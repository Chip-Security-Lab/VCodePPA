//SystemVerilog
module loadable_ring_counter(
    input wire clock,
    input wire reset,
    input wire load,
    input wire [3:0] data_in,
    output wire [3:0] ring_out,
    input wire valid_in,
    output wire valid_out,
    input wire ready_in,
    output wire ready_out
);
    // 将高扇出信号分组以便缓冲
    // 输入缓冲寄存器
    reg load_buf1, load_buf2;
    reg [3:0] data_in_buf1, data_in_buf2;
    reg valid_in_buf1, valid_in_buf2;
    reg ready_in_buf1, ready_in_buf2;
    
    // Pipeline stage registers for data path
    reg [3:0] data_stage1, data_stage2;
    
    // Pipeline stage registers for control signals
    reg load_stage1, load_stage2;
    reg valid_stage1, valid_stage2;
    
    // Valid_stage1缓冲以减少扇出
    reg valid_stage1_buf1, valid_stage1_buf2;
    
    // Pipeline stage status and control
    wire stage1_ready, stage2_ready;
    wire stage1_fire, stage2_fire;
    
    // Ready-valid handshaking logic
    assign stage2_ready = ready_in_buf1 || !valid_stage2;
    assign stage1_ready = stage2_ready || !valid_stage1;
    assign ready_out = stage1_ready;
    
    assign stage1_fire = valid_stage1 && stage2_ready;
    assign stage2_fire = valid_stage2 && ready_in_buf1;
    
    assign valid_out = valid_stage2;
    
    // 输入信号缓冲寄存器 (第一级)
    always @(posedge clock) begin
        if (reset) begin
            load_buf1 <= 1'b0;
            data_in_buf1 <= 4'b0000;
            valid_in_buf1 <= 1'b0;
            ready_in_buf1 <= 1'b0;
        end
        else begin
            load_buf1 <= load;
            data_in_buf1 <= data_in;
            valid_in_buf1 <= valid_in;
            ready_in_buf1 <= ready_in;
        end
    end
    
    // 输入信号缓冲寄存器 (第二级)
    always @(posedge clock) begin
        if (reset) begin
            load_buf2 <= 1'b0;
            data_in_buf2 <= 4'b0000;
            valid_in_buf2 <= 1'b0;
            ready_in_buf2 <= 1'b0;
        end
        else begin
            load_buf2 <= load_buf1;
            data_in_buf2 <= data_in_buf1;
            valid_in_buf2 <= valid_in_buf1;
            ready_in_buf2 <= ready_in_buf1;
        end
    end
    
    // First pipeline stage - control logic
    wire [3:0] next_value_stage1;
    control_logic control_inst (
        .load(load_buf2),
        .data_in(data_in_buf2),
        .current_value(ring_out),
        .next_value(next_value_stage1)
    );
    
    // Pipeline stage 1 registers
    always @(posedge clock) begin
        if (reset) begin
            data_stage1 <= 4'b0000;
            load_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (stage1_ready) begin
            data_stage1 <= next_value_stage1;
            load_stage1 <= load_buf2;
            valid_stage1 <= valid_in_buf2;
        end
    end
    
    // Valid_stage1缓冲寄存器
    always @(posedge clock) begin
        if (reset) begin
            valid_stage1_buf1 <= 1'b0;
            valid_stage1_buf2 <= 1'b0;
        end
        else begin
            valid_stage1_buf1 <= valid_stage1;
            valid_stage1_buf2 <= valid_stage1_buf1;
        end
    end
    
    // Pipeline stage 2 registers
    always @(posedge clock) begin
        if (reset) begin
            data_stage2 <= 4'b0000;
            load_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (stage2_ready) begin
            if (stage1_fire) begin
                data_stage2 <= data_stage1;
                load_stage2 <= load_stage1;
                valid_stage2 <= valid_stage1_buf2; // 使用缓冲后的valid_stage1
            end
            else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Output register block
    register_block register_inst (
        .clock(clock),
        .reset(reset),
        .next_value(data_stage2),
        .load(load_stage2),
        .valid_in(valid_stage2),
        .ready_in(ready_in_buf2),
        .current_value(ring_out)
    );
    
endmodule

// 控制逻辑子模块 - 处理数据选择和移位操作
module control_logic(
    input wire load,
    input wire [3:0] data_in,
    input wire [3:0] current_value,
    output reg [3:0] next_value
);
    always @(*) begin
        if (load)
            next_value = data_in;
        else
            next_value = {current_value[2:0], current_value[3]};
    end
endmodule

// 寄存器子模块 - 增加了流水线控制逻辑
module register_block(
    input wire clock,
    input wire reset,
    input wire [3:0] next_value,
    input wire load,
    input wire valid_in,
    input wire ready_in,
    output reg [3:0] current_value
);
    always @(posedge clock) begin
        if (reset)
            current_value <= 4'b0001;
        else if (valid_in && ready_in)
            current_value <= next_value;
    end
endmodule