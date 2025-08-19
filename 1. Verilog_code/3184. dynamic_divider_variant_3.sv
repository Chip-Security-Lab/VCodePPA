//SystemVerilog
module dynamic_divider #(
    parameter CTR_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [CTR_WIDTH-1:0] div_value,
    input load,
    output reg clk_div
);

// Pipeline stage 1: Counter logic
reg [CTR_WIDTH-1:0] counter_stage1;
reg [CTR_WIDTH-1:0] current_div_stage1;
reg load_stage1;

// Pipeline stage 2: Division logic
reg [CTR_WIDTH-1:0] counter_stage2;
reg [CTR_WIDTH-1:0] current_div_stage2;
reg load_stage2;

// Pipeline stage 3: Output generation
reg [CTR_WIDTH-1:0] counter_stage3;
reg [CTR_WIDTH-1:0] current_div_stage3;
reg load_stage3;

// Stage 1: Counter increment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_stage1 <= 0;
        current_div_stage1 <= 0;
        load_stage1 <= 0;
    end else begin
        if (load) begin
            current_div_stage1 <= div_value;
            counter_stage1 <= 0;
        end else begin
            counter_stage1 <= counter_stage3 >= current_div_stage3-1 ? 0 : counter_stage3 + 1;
            current_div_stage1 <= current_div_stage3;
        end
        load_stage1 <= load;
    end
end

// Stage 2: Division calculation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_stage2 <= 0;
        current_div_stage2 <= 0;
        load_stage2 <= 0;
    end else begin
        counter_stage2 <= counter_stage1;
        current_div_stage2 <= current_div_stage1;
        load_stage2 <= load_stage1;
    end
end

// Stage 3: Output generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_stage3 <= 0;
        current_div_stage3 <= 0;
        load_stage3 <= 0;
        clk_div <= 0;
    end else begin
        counter_stage3 <= counter_stage2;
        current_div_stage3 <= current_div_stage2;
        load_stage3 <= load_stage2;
        
        if (counter_stage2 >= current_div_stage2-1) begin
            clk_div <= ~clk_div;
        end
    end
end

endmodule