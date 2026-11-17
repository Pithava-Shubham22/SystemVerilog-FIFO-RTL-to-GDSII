module FIFO #(parameter WIDTH=8)(
    input logic clk,
    input logic reset,
    input logic wr_en,
    input logic rd_en,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic full,
    output logic empty,
    output logic underflow,
    output logic overflow
);
logic [4:0]occupancy_counter;
logic [WIDTH-1:0] memory_array [0:15];
logic [3:0] write_pointer;
logic [3:0] read_pointer;
logic read_valid;
logic write_valid;

assign read_valid = rd_en && !empty;
assign write_valid = wr_en && !full;

assign empty = (occupancy_counter == 0);
assign full = (occupancy_counter == 16);

always_ff @(posedge clk)
begin
    if(reset)
    begin
        occupancy_counter <= 0;
        write_pointer <= 0;
        read_pointer <= 0;
        data_out<=0;
        overflow <= 0;
        underflow <= 0;
        
        
    end
    else
    begin
        if(write_valid && read_valid)
        begin
            // Simultaneous read and write
            memory_array[write_pointer] <= data_in;
            data_out <= memory_array[read_pointer];
            write_pointer <= (write_pointer + 1) % 16;
            read_pointer <= (read_pointer + 1) % 16;
        end
        else if(write_valid)
        begin
            // Write operation
            memory_array[write_pointer] <= data_in;
            write_pointer <= (write_pointer + 1) % 16;
            occupancy_counter <= occupancy_counter + 1;
        end
        else if(read_valid)
        begin
            // Read operation
            data_out <= memory_array[read_pointer];
            read_pointer <= (read_pointer + 1) % 16;
            occupancy_counter <= occupancy_counter - 1;
        end
            overflow <= wr_en && full;
            underflow <= rd_en && empty;
    end
    
    

end
endmodule 