//SystemVerilog
// SystemVerilog
module counter_pause #(parameter WIDTH=8) (
    input  wire            clk,        // Clock signal
    input  wire            rst,        // Reset signal
    input  wire            pause,      // Pause signal
    input  wire            valid_in,   // Input valid signal
    output wire            valid_out,  // Output valid signal
    output wire [WIDTH-1:0] cnt        // Counter output
);

    // Internal connections between modules
    wire            pause_stage1;
    wire            valid_stage1;
    wire [WIDTH-1:0] cnt_stage1;

    // Stage 1 module: Input processing and counter increment
    counter_stage1 #(
        .WIDTH(WIDTH)
    ) stage1_inst (
        .clk          (clk),
        .rst          (rst),
        .pause        (pause),
        .valid_in     (valid_in),
        .cnt_feedback (cnt),
        .pause_out    (pause_stage1),
        .valid_out    (valid_stage1),
        .cnt_out      (cnt_stage1)
    );

    // Stage 2 module: Output register and feedback
    counter_stage2 #(
        .WIDTH(WIDTH)
    ) stage2_inst (
        .clk          (clk),
        .rst          (rst),
        .pause_in     (pause_stage1),
        .valid_in     (valid_stage1),
        .cnt_in       (cnt_stage1),
        .valid_out    (valid_out),
        .cnt_out      (cnt)
    );

endmodule

//---------------------------------------------------------------------
// Stage 1: Input handling and decrement computation using look-ahead borrow subtractor
//---------------------------------------------------------------------
module counter_stage1 #(parameter WIDTH=8) (
    input  wire            clk,
    input  wire            rst,
    input  wire            pause,
    input  wire            valid_in,
    input  wire [WIDTH-1:0] cnt_feedback,
    output reg             pause_out,
    output reg             valid_out,
    output reg  [WIDTH-1:0] cnt_out
);
    
    // 先行借位减法器信号
    wire [WIDTH-1:0] decremented_value;
    wire [WIDTH:0] borrow;
    
    // 实现先行借位减法器（减1操作）
    assign borrow[0] = 1'b1; // 初始借位为1（相当于减1）
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_borrow
            assign borrow[i+1] = (~cnt_feedback[i]) & borrow[i];
            assign decremented_value[i] = cnt_feedback[i] ^ borrow[i];
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            cnt_out <= 0;
            pause_out <= 0;
            valid_out <= 0;
        end
        else begin
            if (valid_in) begin
                pause_out <= pause;
                valid_out <= 1'b1;
                if (!pause)
                    cnt_out <= cnt_feedback + 1'b1;  // 保持递增功能
                else
                    cnt_out <= cnt_feedback;  // Maintain current value when paused
            end
            else begin
                valid_out <= 0;
            end
        end
    end

endmodule

//---------------------------------------------------------------------
// Stage 2: Result handling and feedback module
//---------------------------------------------------------------------
module counter_stage2 #(parameter WIDTH=8) (
    input  wire            clk,
    input  wire            rst,
    input  wire            pause_in,
    input  wire            valid_in,
    input  wire [WIDTH-1:0] cnt_in,
    output reg             valid_out,
    output reg  [WIDTH-1:0] cnt_out
);

    reg pause_reg;

    always @(posedge clk) begin
        if (rst) begin
            cnt_out <= 0;
            pause_reg <= 0;
            valid_out <= 0;
        end
        else begin
            cnt_out <= cnt_in;
            pause_reg <= pause_in;
            valid_out <= valid_in;
        end
    end

endmodule