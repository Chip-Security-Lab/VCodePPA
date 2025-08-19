//SystemVerilog
module sync_single_port_ram_with_bandwidth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire bandwidth_control,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Pipeline registers with balanced naming
    reg [DATA_WIDTH-1:0] ram_data_pipe;
    reg [DATA_WIDTH-1:0] din_inv_pipe;
    reg [DATA_WIDTH-1:0] sub_result_pipe;
    reg sub_carry_pipe;
    reg [DATA_WIDTH-1:0] final_result_pipe;
    reg we_pipe;
    reg [ADDR_WIDTH-1:0] addr_pipe;
    reg bandwidth_control_pipe;
    
    // Pre-computed constants
    wire [DATA_WIDTH-1:0] din_inv;
    wire [DATA_WIDTH-1:0] sub_result;
    wire sub_carry;
    
    // Stage 1: Inversion and RAM read - balanced logic
    assign din_inv = ~din;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_pipe <= 0;
            din_inv_pipe <= 0;
            addr_pipe <= 0;
            we_pipe <= 0;
            bandwidth_control_pipe <= 0;
        end else begin
            ram_data_pipe <= ram[addr];
            din_inv_pipe <= din_inv;
            addr_pipe <= addr;
            we_pipe <= we;
            bandwidth_control_pipe <= bandwidth_control;
        end
    end

    // Stage 2: Subtraction and result selection - optimized critical path
    assign {sub_carry, sub_result} = ram_data_pipe + din_inv_pipe + 1'b1;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sub_result_pipe <= 0;
            sub_carry_pipe <= 0;
            final_result_pipe <= 0;
        end else if (bandwidth_control_pipe) begin
            sub_result_pipe <= sub_result;
            sub_carry_pipe <= sub_carry;
            final_result_pipe <= sub_carry ? sub_result : ram_data_pipe;
        end
    end

    // Stage 3: RAM write and output - balanced logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (bandwidth_control_pipe) begin
            if (we_pipe) begin
                ram[addr_pipe] <= final_result_pipe;
            end
            dout <= ram_data_pipe;
        end
    end

endmodule