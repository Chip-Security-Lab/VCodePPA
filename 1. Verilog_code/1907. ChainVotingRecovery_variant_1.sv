//SystemVerilog
module ChainVotingRecovery #(parameter WIDTH=4, STAGES=5) (
    input clk,
    input [WIDTH-1:0] noisy_input,
    output reg [WIDTH-1:0] voted_output
);
    // Register moved after combinational logic (forward retiming)
    reg [WIDTH-1:0] delay_chain [1:STAGES-1]; // Reduced size by 1
    wire [WIDTH-1:0] current_input; // Wire for current input
    wire [WIDTH+2:0] sum_bits;  // Wider to accommodate sum
    
    // 条件反相减法器实现所需的信号
    wire [WIDTH+2:0] subtrahend;
    wire [WIDTH+2:0] minuend;
    wire subtract_control;
    wire [WIDTH+2:0] conditional_complement;
    wire [WIDTH+2:0] subtraction_result;
    
    integer i;

    // Register the input directly
    reg [WIDTH-1:0] registered_input;
    always @(posedge clk) begin
        registered_input <= noisy_input;
    end

    // Assign current input to the registered input
    assign current_input = registered_input;
    
    // Shift register chain, starting from position 1
    always @(posedge clk) begin
        i = STAGES-1;
        while (i > 1) begin
            delay_chain[i] <= delay_chain[i-1];
            i = i - 1;
        end
        delay_chain[1] <= current_input;
    end
    
    // 使用条件反相减法器实现比较逻辑
    assign minuend = {3'b000, current_input} + {3'b000, delay_chain[1]} + 
                     {3'b000, delay_chain[2]} + {3'b000, delay_chain[3]} + 
                     {3'b000, delay_chain[4]};
    assign subtrahend = (STAGES/2) + 1'b1; // 阈值加1
    assign subtract_control = 1'b1; // 执行减法操作
    
    // 条件反相减法器核心逻辑
    assign conditional_complement = subtract_control ? ~subtrahend : subtrahend;
    assign subtraction_result = minuend + conditional_complement + subtract_control;
    
    // 使用减法结果的符号位判断大小关系
    assign sum_bits = subtraction_result;
    
    // Decision logic moved after sum calculation
    always @(posedge clk) begin
        voted_output <= subtraction_result[WIDTH+2] ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
    end
endmodule