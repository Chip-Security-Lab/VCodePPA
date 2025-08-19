//SystemVerilog
module rst_sequence_controller (
    input  wire clk,
    input  wire main_rst_n,
    output wire core_rst_n,
    output wire periph_rst_n,
    output wire mem_rst_n
);
    // 增加复位同步深度
    reg [3:0] main_rst_sync;
    
    // 增加计数器流水线阶段
    reg [2:0] seq_counter_stage1;
    reg [2:0] seq_counter_stage2;
    reg [2:0] seq_counter_stage3;
    
    // 增加输出决策寄存器，以减少组合逻辑链
    reg mem_rst_n_stage1, mem_rst_n_stage2; 
    reg periph_rst_n_stage1, periph_rst_n_stage2;
    reg core_rst_n_stage1, core_rst_n_stage2;
    
    // 复位同步阶段和计数器阶段1
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            main_rst_sync <= 4'b0000;
            seq_counter_stage1 <= 3'b000;
        end else begin
            // 更深的复位同步链
            main_rst_sync <= {main_rst_sync[2:0], 1'b1};
            
            // 计数器逻辑在第一级流水线中
            if (main_rst_sync[3] && seq_counter_stage1 != 3'b111)
                seq_counter_stage1 <= seq_counter_stage1 + 1;
        end
    end
    
    // 计数器流水线阶段2和输出计算阶段1
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            seq_counter_stage2 <= 3'b000;
            mem_rst_n_stage1 <= 1'b0;
            periph_rst_n_stage1 <= 1'b0;
            core_rst_n_stage1 <= 1'b0;
        end else begin
            seq_counter_stage2 <= seq_counter_stage1;
            
            // 计算各输出条件的第一阶段
            mem_rst_n_stage1 <= (seq_counter_stage1 >= 3'b001);
            periph_rst_n_stage1 <= (seq_counter_stage1 >= 3'b011);
            core_rst_n_stage1 <= (seq_counter_stage1 >= 3'b111);
        end
    end
    
    // 计数器流水线阶段3和输出计算阶段2
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            seq_counter_stage3 <= 3'b000;
            mem_rst_n_stage2 <= 1'b0;
            periph_rst_n_stage2 <= 1'b0;
            core_rst_n_stage2 <= 1'b0;
        end else begin
            seq_counter_stage3 <= seq_counter_stage2;
            
            // 进一步流水线化输出信号
            mem_rst_n_stage2 <= mem_rst_n_stage1;
            periph_rst_n_stage2 <= periph_rst_n_stage1;
            core_rst_n_stage2 <= core_rst_n_stage1;
        end
    end
    
    // 最终输出分配
    assign mem_rst_n = mem_rst_n_stage2;
    assign periph_rst_n = periph_rst_n_stage2;
    assign core_rst_n = core_rst_n_stage2;
    
endmodule