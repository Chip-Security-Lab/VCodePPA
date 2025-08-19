//SystemVerilog
//IEEE 1364-2005 Verilog
// Top module: LFSR_Shifter
module LFSR_Shifter #(parameter WIDTH=8, TAPS=8'b10001110) (
    input  wire clk,
    input  wire rst,
    output wire serial_out
);
    // Internal connections between modules
    wire feedback_bit;
    wire shift_out_bit;
    wire valid_stage1;
    
    // Instantiate the feedback calculator module
    LFSR_Feedback_Calculator #(
        .WIDTH(WIDTH),
        .TAPS(TAPS)
    ) feedback_calc_inst (
        .lfsr_state(shift_register_inst.lfsr_reg),
        .feedback_bit(feedback_bit)
    );
    
    // Instantiate the shift register module
    LFSR_Shift_Register #(
        .WIDTH(WIDTH)
    ) shift_register_inst (
        .clk(clk),
        .rst(rst),
        .feedback_bit(feedback_bit),
        .shift_out_bit(shift_out_bit),
        .valid_out(valid_stage1)
    );
    
    // Instantiate the output buffer module
    LFSR_Output_Buffer output_buffer_inst (
        .clk(clk),
        .rst(rst),
        .in_bit(shift_out_bit),
        .valid_in(valid_stage1),
        .serial_out(serial_out)
    );
    
endmodule

// Feedback calculator module: Computes feedback bit based on taps
module LFSR_Feedback_Calculator #(parameter WIDTH=8, TAPS=8'b10001110) (
    input  wire [WIDTH-1:0] lfsr_state,
    output wire feedback_bit
);
    // Calculate feedback using XOR of tapped bits
    // 优化：使用位掩码和循环实现，减少门电路资源
    reg feedback;
    integer i;
    
    always @(*) begin
        feedback = 1'b0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (TAPS[i]) 
                feedback = feedback ^ lfsr_state[i];
        end
    end
    
    assign feedback_bit = feedback;
    
endmodule

// Shift register module: Implements pipeline stage 1
module LFSR_Shift_Register #(parameter WIDTH=8) (
    input  wire clk,
    input  wire rst,
    input  wire feedback_bit,
    output wire shift_out_bit,
    output reg  valid_out
);
    // Internal shift register
    reg [WIDTH-1:0] lfsr_reg;
    reg [1:0] counter; // 添加计数器用于控制valid信号
    
    // Pipeline Stage 1: LFSR shift operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_reg <= {WIDTH{1'b1}};
            valid_out <= 1'b0;
            counter <= 2'b00;
        end else begin
            lfsr_reg <= {lfsr_reg[WIDTH-2:0], feedback_bit};
            
            // 优化：延迟valid信号直到LFSR稳定
            if (counter == 2'b10) begin
                valid_out <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    // Output the MSB of the shift register
    assign shift_out_bit = lfsr_reg[WIDTH-1];
    
endmodule

// Output buffer module: Implements pipeline stage 2
module LFSR_Output_Buffer (
    input  wire clk,
    input  wire rst,
    input  wire in_bit,
    input  wire valid_in,
    output wire serial_out
);
    // Registered output and valid signal
    reg out_bit_reg;
    reg valid_reg;
    
    // Pipeline Stage 2: Output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_bit_reg <= 1'b1;
            valid_reg <= 1'b0;
        end else begin
            out_bit_reg <= in_bit;
            valid_reg <= valid_in;
        end
    end
    
    // Final output assignment - 使用valid_reg控制输出，避免无效数据
    assign serial_out = valid_reg ? out_bit_reg : 1'b0;
    
endmodule