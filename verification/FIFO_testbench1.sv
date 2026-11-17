
module testbench;

localparam WIDTH = 8;
localparam DEPTH = 16;

logic clk;
logic reset;
logic wr_en;
logic rd_en;
logic [WIDTH-1:0] data_in;

wire [WIDTH-1:0] data_out;
wire full;
wire empty;
wire overflow;
wire underflow;

integer total_count, pass_count, fail_count;
integer transaction_count;

// Reference model
logic [WIDTH-1:0] reference_fifo[$];

logic [WIDTH-1:0] expected_data;
logic expected_full;
logic expected_empty;
logic expected_overflow;
logic expected_underflow;

// Random stimulus
logic random_wr;
logic random_rd;
logic [WIDTH-1:0] random_data;

// dut instantiation
FIFO #(WIDTH) dut (
    .clk(clk),
    .reset(reset),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty),
    .overflow(overflow),
    .underflow(underflow)
);

// clock initialization
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// variable initialization and dump file
initial
begin
    $dumpfile("FIFO.vcd");
    $dumpvars(0,testbench);

    total_count = 0;
    pass_count = 0;
    fail_count = 0;
    transaction_count = 0;

    reset = 0;
    wr_en = 0;
    rd_en = 0;
    data_in = '0;

    expected_data = '0;
    expected_full = 0;
    expected_empty = 1;
    expected_overflow = 0;
    expected_underflow = 0;
end

// task for check results
task check_result(input integer test_case_number);
begin
    if(data_out === expected_data &&
       full === expected_full &&
       empty === expected_empty &&
       overflow === expected_overflow &&
       underflow === expected_underflow)
    begin
        $display("PASS | Time=%0t | Case=%0d | Data=%h | Full=%b | Empty=%b | Overflow=%b | Underflow=%b",
        $time, test_case_number, data_out, full, empty, overflow, underflow);

        pass_count++;
    end
    else
    begin
        $display("FAIL | Time=%0t | Case=%0d", $time, test_case_number);

        $display("Actual   : Data=%h Full=%b Empty=%b Overflow=%b Underflow=%b",
        data_out, full, empty, overflow, underflow);

        $display("Expected : Data=%h Full=%b Empty=%b Overflow=%b Underflow=%b",
        expected_data, expected_full, expected_empty,
        expected_overflow, expected_underflow);

        fail_count++;
    end

    total_count++;
end
endtask

// task for reset
task reset_fifo(input integer test_case_number);
begin
    @(negedge clk);

    reset = 1;
    wr_en = 0;
    rd_en = 0;
    data_in = 0;

    @(posedge clk);

    reference_fifo.delete();

    expected_data = 0;
    expected_full = 0;
    expected_empty = 1;
    expected_overflow = 0;
    expected_underflow = 0;

    #1;
    check_result(test_case_number);

end
endtask

// task for one FIFO operation and reference model update
task automatic apply_cycle(
    input logic write_request,
    input logic read_request,
    input logic [WIDTH-1:0] write_data,
    input integer test_case_number
);

logic was_full;
logic was_empty;
logic write_accepted;
logic read_accepted;

begin
    @(negedge clk);

    reset = 0;
    wr_en = write_request;
    rd_en = read_request;
    data_in = write_data;

    @(posedge clk);

    // Determine FIFO status before this clock edge
    was_full = (reference_fifo.size() == DEPTH);
    was_empty = (reference_fifo.size() == 0);

    // Determine accepted operations
    write_accepted = write_request && !was_full;
    read_accepted = read_request && !was_empty;

    // Calculate error flags
    expected_overflow = write_request && was_full;
    expected_underflow = read_request && was_empty;

    // Update reference model
    if(read_accepted)
    begin
        expected_data = reference_fifo.pop_front();
    end

    if(write_accepted)
    begin
        reference_fifo.push_back(write_data);
    end

    // Calculate expected status after the operation
    expected_full = (reference_fifo.size() == DEPTH);
    expected_empty = (reference_fifo.size() == 0);

    transaction_count++;

    #1;
    check_result(test_case_number);

end
endtask

// main test sequence
initial
begin

    // test case-1: Reset
    reset_fifo(1);

    // test case-2: Single write and read
    apply_cycle(1, 0, 8'hA8, 2);
    apply_cycle(1, 0, 8'hB5, 2);
    apply_cycle(0, 1, 8'h00, 2);
    apply_cycle(0, 1, 8'h00, 2);

    // test case-3: Overflow
    reset_fifo(3);

    for(int i=0; i<17; i++)
    begin
        apply_cycle(1, 0, i, 3);
    end

    // test case-4: Underflow
    reset_fifo(4);

    apply_cycle(0, 1, 8'h00, 4);

    // test case-5: Normal simultaneous read and write
    reset_fifo(5);

    apply_cycle(1, 0, 8'hA1, 5);
    apply_cycle(1, 0, 8'hB2, 5);
    apply_cycle(1, 1, 8'hC3, 5);
    apply_cycle(0, 1, 8'h00, 5);
    apply_cycle(0, 1, 8'h00, 5);

    // test case-6: Full FIFO
    reset_fifo(6);

    for(int i=0; i<16; i++)
    begin
        apply_cycle(1, 0, i, 6);
    end

    // test case-7: Simultaneous operation when full
    apply_cycle(1, 1, 8'hAA, 7);

    // test case-8: Empty FIFO
    reset_fifo(8);

    // test case-9: Simultaneous operation when empty
    apply_cycle(1, 1, 8'h55, 9);
    apply_cycle(0, 1, 8'h00, 9);

    // test case-10: Pointer wraparound
    reset_fifo(10);

    for(int i=0; i<16; i++)
    begin
        apply_cycle(1, 0, i, 10);
    end

    for(int i=0; i<10; i++)
    begin
        apply_cycle(0, 1, 8'h00, 10);
    end

    for(int i=0; i<10; i++)
    begin
        apply_cycle(1, 0, i+16, 10);
    end

    for(int i=0; i<16; i++)
    begin
        apply_cycle(0, 1, 8'h00, 10);
    end

    // test case-11: Randomized testing
    reset_fifo(11);

    for(int i=0; i<2000000; i++)
    begin
        random_wr = $urandom_range(0,1);
        random_rd = $urandom_range(0,1);
        random_data = $urandom;

        apply_cycle(random_wr, random_rd, random_data, 11);
    end

    // Drain remaining FIFO entries
    while(reference_fifo.size() > 0)
    begin
        apply_cycle(0, 1, 8'h00, 11);
    end

    // Verification summary
    $display("");
    $display("************************************");
    $display(" VERIFICATION SUMMARY ");
    $display("************************************");
    $display(" Total transactions = %0d", transaction_count);
    $display(" Total checks       = %0d", total_count);
    $display(" Total passed       = %0d", pass_count);
    $display(" Total failed       = %0d", fail_count);

    if(fail_count == 0)
        $display(" FIFO VERIFICATION PASSED");
    else
        $display(" FIFO VERIFICATION FAILED");

    $finish;

end

endmodule
