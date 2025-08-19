//SystemVerilog
module counter_preload #(parameter WIDTH=4) (
    input clk,
    input reset,
    input load,
    input en,
    input [WIDTH-1:0] data,
    input data_valid,
    output [WIDTH-1:0] cnt,
    output cnt_valid
);

    // Stage 1: 输入寄存
    reg [WIDTH-1:0] data_stage1;
    reg load_stage1, en_stage1;
    reg data_valid_stage1;
    
    // Stage 2: 计算阶段
    reg [WIDTH-1:0] cnt_stage2;
    reg cnt_valid_stage2;
    
    // Stage 3: 输出寄存
    reg [WIDTH-1:0] cnt_stage3;
    reg cnt_valid_stage3;
    
    // 输出赋值
    assign cnt = cnt_stage3;
    assign cnt_valid = cnt_valid_stage3;
    
    // Stage 1: 分离的输入寄存逻辑
    always @(posedge clk) begin
        if (reset) begin
            data_stage1 <= {WIDTH{1'b0}};
        end
        else begin
            data_stage1 <= data;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            load_stage1 <= 1'b0;
        end
        else begin
            load_stage1 <= load;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            en_stage1 <= 1'b0;
        end
        else begin
            en_stage1 <= en;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            data_valid_stage1 <= 1'b0;
        end
        else begin
            data_valid_stage1 <= data_valid;
        end
    end
    
    // Stage 2: 分离的计算逻辑
    always @(posedge clk) begin
        if (reset) begin
            cnt_stage2 <= {WIDTH{1'b0}};
        end
        else if (data_valid_stage1) begin
            if (load_stage1)
                cnt_stage2 <= data_stage1;
            else if (en_stage1)
                cnt_stage2 <= cnt_stage2 + 1'b1;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            cnt_valid_stage2 <= 1'b0;
        end
        else begin
            cnt_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // Stage 3: 分离的输出寄存逻辑
    always @(posedge clk) begin
        if (reset) begin
            cnt_stage3 <= {WIDTH{1'b0}};
        end
        else begin
            cnt_stage3 <= cnt_stage2;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            cnt_valid_stage3 <= 1'b0;
        end
        else begin
            cnt_valid_stage3 <= cnt_valid_stage2;
        end
    end
    
endmodule