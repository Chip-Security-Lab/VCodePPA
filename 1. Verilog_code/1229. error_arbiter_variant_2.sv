//SystemVerilog IEEE 1364-2005
module error_arbiter #(parameter WIDTH=4) (
    input wire clk, 
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    input wire error_en,
    input wire valid_i,
    output wire valid_o,
    output reg [WIDTH-1:0] grant_o,
    output reg ready_o
);
    // Stage 1: Request processing and priority calculation
    reg [WIDTH-1:0] req_stage1;
    reg error_en_stage1;
    reg valid_stage1;
    wire [WIDTH-1:0] normal_grant_stage1;
    
    // Priority arbiter logic - find lowest priority bit
    assign normal_grant_stage1 = req_stage1 & (~req_stage1 + 1);
    
    // Stage 1 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage1 <= {WIDTH{1'b0}};
            error_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (ready_o) begin
            req_stage1 <= req_i;
            error_en_stage1 <= error_en;
            valid_stage1 <= valid_i;
        end
    end
    
    // Stage 2: Grant generation
    reg [WIDTH-1:0] normal_grant_stage2;
    reg error_en_stage2;
    reg valid_stage2;
    
    // Stage 2 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            normal_grant_stage2 <= {WIDTH{1'b0}};
            error_en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            normal_grant_stage2 <= normal_grant_stage1;
            error_en_stage2 <= error_en_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end
        else begin
            grant_o <= error_en_stage2 ? {WIDTH{1'b1}} : normal_grant_stage2;
        end
    end
    
    // Pipeline control signals
    assign valid_o = valid_stage2;
    
    // Ready signal generation - simplistic backpressure handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_o <= 1'b1;
        end
        else begin
            ready_o <= 1'b1; // Always ready in this implementation
            // In a more complex design, ready_o would depend on downstream ready signals
        end
    end
endmodule