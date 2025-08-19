//SystemVerilog
module shift_reg_barrel_shifter #(
    parameter WIDTH = 16
)(
    input                      clk,
    input                      en,
    input      [WIDTH-1:0]     data_in,
    input      [$clog2(WIDTH)-1:0] shift_amount,
    output reg [WIDTH-1:0]     data_out
);
    // 定义位移位数为常量
    localparam LOG2_WIDTH = $clog2(WIDTH);
    
    // 查找表存储预计算的移位结果
    reg [WIDTH-1:0] shift_lut [0:(1<<LOG2_WIDTH)-1];
    
    // 移位操作中间结果
    reg [WIDTH-1:0] shifted_data;
    reg update_lut;
    reg [LOG2_WIDTH-1:0] j_counter;
    reg [LOG2_WIDTH-1:0] i_counter;
    reg [WIDTH-1:0] temp_data;
    
    // FSM状态定义
    typedef enum logic [1:0] {
        IDLE,
        COMPUTE_LUT,
        SHIFT_BITS,
        OUTPUT_RESULT
    } state_t;
    
    state_t current_state, next_state;
    
    // 初始化查找表
    initial begin
        integer i;
        for (i = 0; i < (1<<LOG2_WIDTH); i = i + 1) begin
            shift_lut[i] = {WIDTH{1'b0}};
        end
    end
    
    // 状态寄存器
    always @(posedge clk) begin
        current_state <= next_state;
    end
    
    // 状态转移逻辑
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (en) begin
                    next_state = COMPUTE_LUT;
                end
            end
            
            COMPUTE_LUT: begin
                if (j_counter == (1<<LOG2_WIDTH) - 1) begin
                    next_state = OUTPUT_RESULT;
                end
            end
            
            SHIFT_BITS: begin
                if (i_counter == LOG2_WIDTH - 1) begin
                    next_state = COMPUTE_LUT;
                end
            end
            
            OUTPUT_RESULT: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // j计数器逻辑
    always @(posedge clk) begin
        if (current_state == IDLE && next_state == COMPUTE_LUT) begin
            j_counter <= 0;
        end else if (current_state == COMPUTE_LUT && i_counter == LOG2_WIDTH - 1 && next_state == COMPUTE_LUT) begin
            j_counter <= j_counter + 1;
        end
    end
    
    // i计数器逻辑
    always @(posedge clk) begin
        if (current_state == COMPUTE_LUT && next_state == SHIFT_BITS) begin
            i_counter <= 0;
        end else if (current_state == SHIFT_BITS && next_state == SHIFT_BITS) begin
            i_counter <= i_counter + 1;
        end
    end
    
    // 数据处理逻辑
    always @(posedge clk) begin
        case (current_state)
            IDLE: begin
                if (next_state == COMPUTE_LUT) begin
                    temp_data <= data_in;
                end
            end
            
            COMPUTE_LUT: begin
                if (next_state == SHIFT_BITS) begin
                    shifted_data <= temp_data;
                end
            end
            
            SHIFT_BITS: begin
                if (j_counter[i_counter]) begin
                    shifted_data <= (shifted_data << (1 << i_counter));
                end
                
                if (i_counter == LOG2_WIDTH - 1) begin
                    shift_lut[j_counter] <= shifted_data;
                end
            end
            
            OUTPUT_RESULT: begin
                data_out <= shift_lut[shift_amount];
            end
        endcase
    end
    
endmodule