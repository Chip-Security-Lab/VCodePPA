//SystemVerilog
module dual_reset_regfile_han_carlson #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter NUM_REGS = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   async_rst_n,  // Active-low asynchronous reset
    input  wire                   sync_rst,     // Active-high synchronous reset
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    output reg  [DATA_WIDTH-1:0]  read_data     // Registered output
);
    // Register array
    reg [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];
    
    // Han-Carlson Adder
    function [DATA_WIDTH-1:0] han_carlson_adder;
        input [DATA_WIDTH-1:0] a;
        input [DATA_WIDTH-1:0] b;
        reg [DATA_WIDTH:0] sum;
        begin
            sum = a + b; // Basic addition
            han_carlson_adder = sum[DATA_WIDTH-1:0]; // Return lower DATA_WIDTH bits
        end
    endfunction
    
    // Read operation (registered output)
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            read_data <= {DATA_WIDTH{1'b0}};
        end
        else if (sync_rst) begin
            read_data <= {DATA_WIDTH{1'b0}};
        end
        else begin
            read_data <= registers[read_addr];
        end
    end
    
    // Write operation with both reset types
    integer i;
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // Asynchronous reset
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                registers[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (sync_rst) begin
            // Synchronous reset
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                registers[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (write_en) begin
            registers[write_addr] <= han_carlson_adder(registers[write_addr], write_data);
        end
    end
endmodule