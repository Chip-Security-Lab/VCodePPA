//SystemVerilog
module parity_decoder (
    input wire clk,          // System clock input
    input wire rst_n,        // Active low reset
    input wire [2:0] addr,   // Address input
    input wire parity_bit,   // Parity bit input
    output reg [7:0] select, // Output selection lines
    output reg parity_error  // Parity error indicator
);

    // Internal pipeline registers
    reg [2:0] addr_stage1;
    reg parity_bit_stage1;
    reg parity_check_result;
    reg [2:0] addr_stage2;
    
    // Stage 1: Input Registration and Parity Calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 3'b000;
            parity_bit_stage1 <= 1'b0;
            parity_check_result <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            parity_bit_stage1 <= parity_bit;
            parity_check_result <= ^addr ^ parity_bit;
        end
    end
    
    // Stage 2: Error Propagation and Address Registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_error <= 1'b0;
            addr_stage2 <= 3'b000;
        end else begin
            parity_error <= parity_check_result;
            addr_stage2 <= addr_stage1;
        end
    end
    
    // Stage 3: Output Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= 8'h00;
        end else begin
            select <= parity_error ? 8'h00 : (8'h01 << addr_stage2);
        end
    end

endmodule