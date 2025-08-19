//SystemVerilog
module fully_registered_decoder(
    input clk,
    input rst,
    input [2:0] addr_in,
    output reg [7:0] decode_out
);
    // Pipeline stage 1 registers
    reg [2:0] addr_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [2:0] addr_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1: Register input
    always @(posedge clk) begin
        if (rst) begin
            addr_stage1 <= 3'b000;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr_in;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Register middle stage
    always @(posedge clk) begin
        if (rst) begin
            addr_stage2 <= 3'b000;
            valid_stage2 <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Decode and register output
    always @(posedge clk) begin
        if (rst) begin
            decode_out <= 8'b00000000;
        end else if (valid_stage2) begin
            decode_out <= (8'b00000001 << addr_stage2);
        end else begin
            decode_out <= decode_out;
        end
    end
endmodule