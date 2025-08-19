module adder_behavioral (
    input  wire        clk,        // Clock signal
    input  wire        rst_n,      // Active-low reset
    input  wire [3:0]  a_in,       // Input operand A
    input  wire [3:0]  b_in,       // Input operand B
    output wire [3:0]  sum_out,    // Sum output
    output wire        carry_out   // Carry output
);

    // Buffered clocks
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Internal connections
    wire [3:0] a_reg, b_reg;
    wire [4:0] sum_internal;

    // Clock buffer module instantiation
    clock_buffer_tree clock_buf (
        .clk_in(clk),
        .rst_n(rst_n),
        .clk_out1(clk_buf1),
        .clk_out2(clk_buf2),
        .clk_out3(clk_buf3)
    );
    
    // Input registration module
    input_register input_reg (
        .clk(clk_buf1),
        .rst_n(rst_n),
        .a_in(a_in),
        .b_in(b_in),
        .a_reg(a_reg),
        .b_reg(b_reg)
    );
    
    // Computation module
    computation_stage comp_stage (
        .clk(clk_buf2),
        .rst_n(rst_n),
        .a_reg(a_reg),
        .b_reg(b_reg),
        .sum_internal(sum_internal)
    );
    
    // Output registration module
    output_register output_reg (
        .clk(clk_buf3),
        .rst_n(rst_n),
        .sum_internal(sum_internal),
        .sum_out(sum_out),
        .carry_out(carry_out)
    );
    
endmodule

// Clock buffer tree module
module clock_buffer_tree (
    input  wire clk_in,   // Input clock
    input  wire rst_n,    // Reset signal
    output wire clk_out1, // Buffered clock 1
    output wire clk_out2, // Buffered clock 2
    output wire clk_out3  // Buffered clock 3
);
    // Clock buffer implementation
    (* dont_touch = "true" *) reg clk_buf_reg1;
    (* dont_touch = "true" *) reg clk_buf_reg2;
    (* dont_touch = "true" *) reg clk_buf_reg3;
    
    always @(posedge clk_in) begin
        clk_buf_reg1 <= 1'b1;
        clk_buf_reg2 <= 1'b1;
        clk_buf_reg3 <= 1'b1;
    end
    
    assign clk_out1 = clk_in & clk_buf_reg1;
    assign clk_out2 = clk_in & clk_buf_reg2;
    assign clk_out3 = clk_in & clk_buf_reg3;
    
endmodule

// Input registration module
module input_register (
    input  wire        clk,     // Buffered clock
    input  wire        rst_n,   // Reset signal
    input  wire [3:0]  a_in,    // Input operand A
    input  wire [3:0]  b_in,    // Input operand B
    output reg  [3:0]  a_reg,   // Registered operand A
    output reg  [3:0]  b_reg    // Registered operand B
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0000;
            b_reg <= 4'b0000;
        end else begin
            a_reg <= a_in;
            b_reg <= b_in;
        end
    end
    
endmodule

// Computation module
module computation_stage (
    input  wire        clk,           // Buffered clock
    input  wire        rst_n,         // Reset signal
    input  wire [3:0]  a_reg,         // Registered operand A
    input  wire [3:0]  b_reg,         // Registered operand B
    output reg  [4:0]  sum_internal   // Internal sum with carry
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_internal <= 5'b00000;
        end else begin
            sum_internal <= a_reg + b_reg;
        end
    end
    
endmodule

// Output registration module
module output_register (
    input  wire        clk,           // Buffered clock
    input  wire        rst_n,         // Reset signal
    input  wire [4:0]  sum_internal,  // Internal sum with carry
    output reg  [3:0]  sum_out,       // Final sum output
    output reg         carry_out      // Final carry output
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out   <= 4'b0000;
            carry_out <= 1'b0;
        end else begin
            sum_out   <= sum_internal[3:0];
            carry_out <= sum_internal[4];
        end
    end
    
endmodule