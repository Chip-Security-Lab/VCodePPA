//SystemVerilog
module counter_dual_edge #(parameter WIDTH=4) (
    input wire clk, rst,
    output reg [WIDTH-1:0] cnt,
    
    // Pipeline control signals
    input wire pipe_valid_in,
    output reg pipe_valid_out,
    input wire pipe_ready_in,
    output wire pipe_ready_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] pos_cnt;
    reg [WIDTH-1:0] neg_cnt;
    
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] pos_cnt_stage1;
    reg [WIDTH-1:0] neg_cnt_stage1;
    reg pipe_valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] sum_stage2;
    reg pipe_valid_stage2;
    
    // Flow control
    wire stage1_ready;
    wire stage2_ready;
    
    assign pipe_ready_out = stage1_ready;
    assign stage1_ready = !pipe_valid_stage1 || stage2_ready;
    assign stage2_ready = !pipe_valid_stage2 || pipe_ready_in;
    
    // Posedge counter with pipeline control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pos_cnt <= 0;
        end
        else if (stage1_ready) begin
            pos_cnt <= pos_cnt + 1;
        end
    end
    
    // Negedge counter with pipeline control
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            neg_cnt <= 0;
        end
        else if (stage1_ready) begin
            neg_cnt <= neg_cnt + 1;
        end
    end
    
    // Pipeline stage 1: Register counter values
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pos_cnt_stage1 <= 0;
            neg_cnt_stage1 <= 0;
            pipe_valid_stage1 <= 0;
        end
        else if (stage1_ready) begin
            pos_cnt_stage1 <= pos_cnt;
            neg_cnt_stage1 <= neg_cnt;
            pipe_valid_stage1 <= pipe_valid_in;
        end
    end
    
    // Pipeline stage 2: Calculate sum
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_stage2 <= 0;
            pipe_valid_stage2 <= 0;
        end
        else if (stage2_ready) begin
            sum_stage2 <= pos_cnt_stage1 + neg_cnt_stage1;
            pipe_valid_stage2 <= pipe_valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            pipe_valid_out <= 0;
        end
        else if (pipe_ready_in) begin
            cnt <= sum_stage2;
            pipe_valid_out <= pipe_valid_stage2;
        end
    end
endmodule