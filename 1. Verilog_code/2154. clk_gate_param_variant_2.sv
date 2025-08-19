//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module clk_gate_param #(parameter DW=8, AW=4) (
    input clk,
    input rst_n,     // Added reset signal for proper pipeline control
    input en,
    input valid_in,  // Input valid signal
    input [AW-1:0] addr,
    output reg [DW-1:0] data,
    output reg valid_out // Output valid signal
);
    // Pipeline stage signals
    // Stage 1 - Address calculation
    reg [AW-1:0] addr_stage1;
    reg en_stage1;
    reg valid_stage1;
    
    // Stage 2 - Shift operation
    reg [AW-1:0] addr_stage2;
    reg [DW-1:0] shifted_data_stage2;
    reg en_stage2;
    reg valid_stage2;
    
    // Stage 3 - Output generation
    reg [DW-1:0] data_stage3;
    reg valid_stage3;
    
    // Stage 1: Register input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {AW{1'b0}};
            en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            en_stage1 <= en;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Register address and perform initial calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= {AW{1'b0}};
            shifted_data_stage2 <= {DW{1'b0}};
            en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            shifted_data_stage2 <= {addr_stage1, 2'b00}; // Shift left by 2 (optimized)
            en_stage2 <= en_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Apply enable control and finalize data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            data_stage3 <= en_stage2 ? shifted_data_stage2 : {DW{1'b0}};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data <= data_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule