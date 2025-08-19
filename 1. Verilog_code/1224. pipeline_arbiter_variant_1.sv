//SystemVerilog
module pipeline_arbiter #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o,
    // Pipeline control signals
    input wire valid_i,
    output reg valid_o,
    input wire ready_i,
    output wire ready_o
);

    // Internal signals for pipeline stages
    reg [WIDTH-1:0] stage1_data;
    reg [WIDTH-1:0] stage2_data;
    
    // Pipeline control registers
    reg valid_stage1;
    reg valid_stage2;
    
    // Combinational signals
    wire [WIDTH-1:0] priority_encoded_req;
    wire stage1_ready;
    wire stage2_ready;
    
    // Combinational logic - Priority encoder
    assign priority_encoded_req = req_i & (~req_i + 1);
    
    // Combinational logic - Backpressure handling
    assign stage2_ready = ready_i || !valid_stage2;
    assign stage1_ready = stage2_ready || !valid_stage1;
    assign ready_o = stage1_ready;
    
    // Sequential logic - Pipeline registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline stages
            stage1_data <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (stage1_ready) begin
            // Stage 1: First pipeline stage
            stage1_data <= priority_encoded_req;
            valid_stage1 <= valid_i;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset second pipeline stage
            stage2_data <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (stage2_ready) begin
            // Stage 2: Second pipeline stage
            stage2_data <= stage1_data;
            valid_stage2 <= valid_stage1;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset output stage
            grant_o <= {WIDTH{1'b0}};
            valid_o <= 1'b0;
        end else if (ready_i || !valid_o) begin
            // Stage 3: Output stage
            grant_o <= stage2_data;
            valid_o <= valid_stage2;
        end
    end

endmodule