//SystemVerilog
module sync_single_port_ram_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    reg [2:0] state;
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] din_stage1;
    reg we_stage1;
    reg [DATA_WIDTH-1:0] ram_data_stage2;
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg we_stage2;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 3'b000;
            dout <= 0;
            addr_stage1 <= 0;
            din_stage1 <= 0;
            we_stage1 <= 0;
            ram_data_stage2 <= 0;
            addr_stage2 <= 0;
            we_stage2 <= 0;
        end else begin
            // Stage 1: Input Register
            addr_stage1 <= addr;
            din_stage1 <= din;
            we_stage1 <= we;
            
            // Stage 2: RAM Access
            addr_stage2 <= addr_stage1;
            we_stage2 <= we_stage1;
            if (we_stage1) begin
                ram[addr_stage1] <= din_stage1;
            end
            ram_data_stage2 <= ram[addr_stage1];
            
            // Stage 3: Output Register
            dout <= ram_data_stage2;
            
            // State Machine
            case (state)
                3'b000: begin
                    if (we_stage2) begin
                        state <= 3'b001;
                    end else begin
                        state <= 3'b010;
                    end
                end
                3'b001: begin
                    state <= 3'b010;
                end
                3'b010: begin
                    if (we_stage2) begin
                        state <= 3'b001;
                    end else begin
                        state <= 3'b010;
                    end
                end
                default: state <= 3'b000;
            endcase
        end
    end
endmodule