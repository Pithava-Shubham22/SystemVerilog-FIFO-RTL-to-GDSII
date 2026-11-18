module testbench;

localparam WIDTH = 8;

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

integer total_count, pass_count, fail_count, j;

reg [WIDTH-1:0] expected_data;
reg expected_full;
reg expected_empty;
reg expected_overflow;
reg expected_underflow;

logic [WIDTH-1:0] reference_fifo[$];

reg [WIDTH-1:0] random_data;
reg random_wr;
reg random_rd;

integer wr_prob;
integer rd_prob;

integer wr_disabled_count;
integer wr_enabled_count;

integer rd_disabled_count;
integer rd_enabled_count;

integer empty_count;
integer normal_count;
integer full_count;

integer overflow_count;
integer underflow_count;

integer simultaneous_count;
integer simultaneous_full_count;
integer simultaneous_empty_count;

integer scenario_hit;
integer scenario_total;

// Procedural assertion checker variables
logic checker_armed;
logic exp_overflow_flag;
logic exp_underflow_flag;

// DUT instantiation
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


// Clock initialization
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end


// Variable initialization
initial begin
    $dumpfile("FIFO.vcd");
    $dumpvars(0, testbench);

    total_count = 0;
    pass_count = 0;
    fail_count = 0;

    reset = 1;
    wr_en = 0;
    rd_en = 0;
    data_in = '0;

    expected_data = '0;
    expected_full = 0;
    expected_empty = 1;
    expected_overflow = 0;
    expected_underflow = 0;
    
    wr_prob = 50;
    rd_prob = 50;

    wr_disabled_count = 0;
    wr_enabled_count = 0;

    rd_disabled_count = 0;
    rd_enabled_count = 0;

    empty_count = 0;
    normal_count = 0;
    full_count = 0;

    overflow_count = 0;
    underflow_count = 0;

    simultaneous_count = 0;
    simultaneous_full_count = 0;
    simultaneous_empty_count = 0;

    scenario_hit = 0;
    scenario_total = 0;

    checker_armed = 0;
    exp_overflow_flag = 0;
    exp_underflow_flag = 0;

    reference_fifo.delete();
end


// Task for checking results
task check_result(
    input logic [WIDTH-1:0] expected_data,
    input logic expected_full,
    input logic expected_empty,
    input logic expected_overflow,
    input logic expected_underflow,
    input integer test_case_number
);
begin
    if (
        data_out === expected_data &&
        full === expected_full &&
        empty === expected_empty &&
        overflow === expected_overflow &&
        underflow === expected_underflow
    )
    begin
        pass_count++;
    end
    else
    begin
        $display(
            "Test failed at time %0t | test case=%0d: data_out=%0b | expected_out=%0b, full=%0b | expected_full=%0b, empty=%0b | expected_empty=%0b, overflow=%0b | expected_overflow=%0b, underflow=%0b | expected_underflow=%0b",
            $time, test_case_number,
            data_out, expected_data,
            full, expected_full,
            empty, expected_empty,
            overflow, expected_overflow,
            underflow, expected_underflow
        );

        fail_count++;
    end

    total_count++;
end
endtask


task automatic collect_coverage();

begin

    // Write request coverage
    if (wr_en == 0)
        wr_disabled_count++;
    else
        wr_enabled_count++;

    // Read request coverage
    if (rd_en == 0)
        rd_disabled_count++;
    else
        rd_enabled_count++;

    // FIFO status coverage
    if (empty)
        empty_count++;
    else if (full)
        full_count++;
    else
        normal_count++;

    // Error coverage
    if (overflow)
        overflow_count++;

    if (underflow)
        underflow_count++;

    // Simultaneous operation coverage
    if (wr_en && rd_en)
        simultaneous_count++;

end
endtask


// Task for reporting scenario coverage
task automatic report_scenario(
    input string scenario_name,
    input integer scenario_count
);
begin
    scenario_total++;

    if (scenario_count > 0)
    begin
        scenario_hit++;
        $display("%-28s : %0d [HIT]", scenario_name, scenario_count);
    end
    else
    begin
        $display("%-28s : %0d [NOT HIT]", scenario_name, scenario_count);
    end
end
endtask


// Task for reset | Test case-1
task reset_fifo();
begin
    wr_en = 0;
    rd_en = 0;
    data_in = '0;
    reset = 1;

    @(posedge clk);
    #1;

    reference_fifo.delete();

    expected_data = '0;
    expected_full = 0;
    expected_empty = 1;
    expected_overflow = 0;
    expected_underflow = 0;
    
    check_result(8'b0, 0, 1, 0, 0, 1);

    reset = 0;

    @(posedge clk);
    #1;
    collect_coverage();
    check_result(8'b0, 0, 1, 0, 0, 1);
end
endtask


// Task for write operation | Test case-2
task write_fifo(input logic [WIDTH-1:0] data);
begin
    reset = 0;
    wr_en = 1;
    rd_en = 0;
    data_in = data;

    @(posedge clk);
    #1;
    collect_coverage();

    check_result(8'h00, 0, 0, 0, 0, 2);
end
endtask


// Task for read operation | Test case-3
task read_fifo();
begin
    reset = 0;
    wr_en = 0;
    rd_en = 1;

    @(posedge clk);
    #1;
    collect_coverage();

    check_result(8'hA8, 0, 1, 0, 0, 3);
end
endtask


// Task for overflow test | Test case-4
task overflow_fifo();
begin
    reset = 0;
    wr_en = 1;
    rd_en = 0;

    for (int i = 0; i < 17; i++)
    begin
        data_in = i;
        @(posedge clk);
        #1;
        collect_coverage();
    end

    
    check_result(8'h00, 1, 0, 1, 0, 4);
end
endtask


// Task for underflow test | Test case-5
task underflow_fifo();
begin
    reset = 0;
    wr_en = 0;
    rd_en = 1;

    @(posedge clk);
    #1;
    collect_coverage();

    check_result(8'h00, 0, 1, 0, 1, 5);
end
endtask


// Task for simultaneous read and write | Test case-6
task simultaneous_read_write();
begin
    reset = 0;
    wr_en = 1;
    rd_en = 0;

    data_in = 8'h11;
    @(posedge clk);
    #1;

    data_in = 8'h22;
    @(posedge clk);
    #1;

    wr_en = 1;
    rd_en = 1;
    data_in = 8'h55;

    @(posedge clk);
    #1;
    collect_coverage();


    check_result(8'h11, 0, 0, 0, 0, 6);
end
endtask


// Task for full FIFO | Test case-7
task full_fifo();
begin
    reset = 0;
    wr_en = 1;
    rd_en = 0;

    for (int i = 0; i < 16; i++)
    begin
        data_in = i;
        @(posedge clk);
        #1;
    end
        
    check_result(8'h00, 1, 0, 0, 0, 7);
end
endtask


// Task for empty FIFO | Test case-8
task empty_fifo();
begin
    reset = 0;
    wr_en = 1;
    rd_en = 0;

    for (int i = 0; i < 16; i++)
    begin
        data_in = i;
        @(posedge clk);
        #1;
        collect_coverage();
    end

    wr_en = 0;
    rd_en = 1;

    for (int i = 0; i < 16; i++)
    begin
        @(posedge clk);
        #1;
    end
    
    collect_coverage();         
    check_result(8'h0F, 0, 1, 0, 0, 8);
end
endtask


// Task for simultaneous operation when full | Test case-9
task simultaneous_read_write_overflow();
begin
    reset = 0;
    wr_en = 1;
    rd_en = 0;

    for (int i = 0; i < 16; i++)
    begin
        data_in = i;
        @(posedge clk);
        #1;
        collect_coverage();
    end

    wr_en = 1;
    rd_en = 1;
    data_in = 8'hAA;

    // Capture pre-edge FIFO status
    if (full)
        simultaneous_full_count++;

    @(posedge clk);
    #1;
    collect_coverage();

    check_result(8'h00, 0, 0, 1, 0, 9);
    
end
endtask


// Task for simultaneous operation when empty | Test case-10
task simultaneous_read_write_underflow();
begin
    reset = 0;
    wr_en = 1;
    rd_en = 1;
    data_in = 8'hAA;

    // Capture pre-edge FIFO status
    if (empty)
        simultaneous_empty_count++;

    @(posedge clk);
    #1;
    collect_coverage();
    check_result(8'h00, 0, 0, 0, 1, 10);
end
endtask


// Reference-model transaction task
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
    was_full = (reference_fifo.size() == 16);
    was_empty = (reference_fifo.size() == 0);
    if (write_request && read_request)
begin
    if (was_full)
        simultaneous_full_count++;

    if (was_empty)
        simultaneous_empty_count++;
end

    // Determine accepted operations
    write_accepted = write_request && !was_full;
    read_accepted = read_request && !was_empty;

    // Calculate error flags
    expected_overflow = write_request && was_full;
    expected_underflow = read_request && was_empty;

    // Update reference FIFO model
    if (read_accepted)
    begin
        expected_data = reference_fifo.pop_front();
    end

    if (write_accepted)
    begin
        reference_fifo.push_back(write_data);
    end

    // Calculate expected status after the operation
    expected_full = (reference_fifo.size() == 16);
    expected_empty = (reference_fifo.size() == 0);
    

    #1;
    collect_coverage();

    check_result(
        expected_data,
        expected_full,
        expected_empty,
        expected_overflow,
        expected_underflow,
        test_case_number
    );

end
endtask


// Main test sequence
initial begin

    @(negedge clk);

    reset_fifo();
    write_fifo(8'hA8);
    read_fifo();

    reset_fifo();
    overflow_fifo();

    reset_fifo();
    underflow_fifo();

    reset_fifo();
    simultaneous_read_write();

    reset_fifo();
    full_fifo();

    reset_fifo();
    empty_fifo();

    reset_fifo();
    simultaneous_read_write_overflow();

    reset_fifo();
    simultaneous_read_write_underflow();

    reset_fifo();

    for (j = 0; j < 300; j++)
    begin
        // Weighted random phases: write-heavy, read-heavy, balanced
        if (j < 100)
        begin
            wr_prob = 75;
            rd_prob = 25;
        end
        else if (j < 200)
        begin
            wr_prob = 25;
            rd_prob = 75;
        end
        else
        begin
            wr_prob = 50;
            rd_prob = 50;
        end

        random_wr = ($urandom_range(0, 99) < wr_prob);
        random_rd = ($urandom_range(0, 99) < rd_prob);
        random_data = $urandom;

        apply_cycle(random_wr, random_rd, random_data, 11);
    end

    $display("************************************");
    $display(" VERIFICATION SUMMARY ");
    $display("************************************");
    $display(" total_test_count = %0d", total_count);
    $display(" total_pass_count = %0d", pass_count);
    $display(" total_fail_count = %0d", fail_count);

    if (fail_count == 0)
        $display(" FIFO VERIFICATION PASSED");
    else
        $display(" FIFO VERIFICATION FAILED");

    $display("");
$display("========================================");
$display("       FUNCTIONAL COVERAGE SUMMARY      ");
$display("========================================");

$display("Write Disabled       : %0d", wr_disabled_count);
$display("Write Enabled        : %0d", wr_enabled_count);

$display("Read Disabled        : %0d", rd_disabled_count);
$display("Read Enabled         : %0d", rd_enabled_count);

$display("FIFO Empty           : %0d", empty_count);
$display("FIFO Normal          : %0d", normal_count);
$display("FIFO Full            : %0d", full_count);

$display("Overflow             : %0d", overflow_count);
$display("Underflow            : %0d", underflow_count);

$display("Simultaneous R/W     : %0d", simultaneous_count);
$display("Simultaneous Full     : %0d", simultaneous_full_count);
$display("Simultaneous Empty    : %0d", simultaneous_empty_count);

$display("----------------------------------------");
$display("          SCENARIO COVERAGE             ");
$display("----------------------------------------");

report_scenario("Write Disabled", wr_disabled_count);
report_scenario("Write Enabled", wr_enabled_count);
report_scenario("Read Disabled", rd_disabled_count);
report_scenario("Read Enabled", rd_enabled_count);
report_scenario("FIFO Empty", empty_count);
report_scenario("FIFO Normal", normal_count);
report_scenario("FIFO Full", full_count);
report_scenario("Overflow", overflow_count);
report_scenario("Underflow", underflow_count);
report_scenario("Simultaneous R/W", simultaneous_count);
report_scenario("Simultaneous R/W when Full", simultaneous_full_count);
report_scenario("Simultaneous R/W when Empty", simultaneous_empty_count);

$display("----------------------------------------");
$display("SCENARIO COVERAGE = %0d / %0d (%0.2f%%)", scenario_hit, scenario_total, (scenario_hit * 100.0) / scenario_total);

$display("========================================");
    
    $finish;

end


// Procedural assertion checker (works without SVA support in free simulators)
always @(posedge clk)
begin
    if (checker_armed)
    begin
        // Assertion 1: FIFO cannot be full and empty simultaneously
        if (!reset && full && empty)
        begin
            $display("FIFO ERROR: FULL and EMPTY asserted together at time %0t", $time);
            fail_count++;
        end

        // Assertion 2: underflow flag must follow (rd_en && empty) from the previous edge
        if (underflow !== exp_underflow_flag)
        begin
            $display("FIFO assertion underflow failed at time %0t", $time);
            fail_count++;
        end

        // Assertion 3: overflow flag must follow (wr_en && full) from the previous edge
        if (overflow !== exp_overflow_flag)
        begin
            $display("FIFO overflow assertion failed at time %0t", $time);
            fail_count++;
        end

        // Assertion 4: occupancy counter must never exceed FIFO depth
        if (dut.occupancy_counter > 5'd16)
        begin
            $display("FIFO ERROR: occupancy counter exceeded depth at time %0t", $time);
            fail_count++;
        end
    end

    // Expected flags for the next edge, based on pre-edge status
    if (reset)
    begin
        exp_overflow_flag = 0;
        exp_underflow_flag = 0;
    end
    else
    begin
        exp_overflow_flag = (wr_en && full);
        exp_underflow_flag = (rd_en && empty);
    end

    checker_armed = 1;
end

endmodule
