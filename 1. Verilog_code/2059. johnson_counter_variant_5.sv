//SystemVerilog
module johnson_counter #(parameter WIDTH = 4) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   enable,
    output reg  [WIDTH-1:0]       johnson_code
);

    // State encoding
    localparam STATE_RESET  = 2'b00;
    localparam STATE_ENABLE = 2'b01;
    localparam STATE_IDLE   = 2'b10;

    // Stage 1: Input synchronization and state transition logic
    reg        rst_n_stage1;
    reg        enable_stage1;
    reg [1:0]  state_next_stage1;
    reg        valid_stage1;
    reg        flush_stage1;

    // Stage 2: Johnson code next value calculation
    reg [1:0]  state_next_stage2;
    reg [WIDTH-1:0] johnson_code_stage2;
    reg        valid_stage2;
    reg        flush_stage2;

    // Stage 3: Output register update
    reg [WIDTH-1:0] johnson_code_stage3;
    reg        valid_stage3;
    reg        flush_stage3;

    // Pipeline control
    wire       flush;
    assign     flush = ~rst_n; // Flush pipeline on reset

    // Stage 1: Latch inputs and calculate next state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_stage1     <= 1'b0;
            enable_stage1    <= 1'b0;
            state_next_stage1<= STATE_RESET;
            valid_stage1     <= 1'b0;
            flush_stage1     <= 1'b1;
        end else begin
            rst_n_stage1     <= rst_n;
            enable_stage1    <= enable;
            // Next state logic
            case ({~rst_n, enable})
                2'b10: state_next_stage1 = STATE_RESET;   // !rst_n
                2'b01: state_next_stage1 = STATE_ENABLE;  // rst_n && enable
                default: state_next_stage1 = STATE_IDLE;  // rst_n && !enable
            endcase
            valid_stage1     <= 1'b1;
            flush_stage1     <= flush;
        end
    end

    // Stage 2: Calculate next Johnson code value based on state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            johnson_code_stage2   <= {WIDTH{1'b0}};
            state_next_stage2     <= STATE_RESET;
            valid_stage2          <= 1'b0;
            flush_stage2          <= 1'b1;
        end else begin
            state_next_stage2     <= state_next_stage1;
            // Johnson code update logic
            case (state_next_stage1)
                STATE_RESET:  johnson_code_stage2 <= {WIDTH{1'b0}};
                STATE_ENABLE: johnson_code_stage2 <= {~johnson_code, johnson_code[WIDTH-1:1]};
                default:      johnson_code_stage2 <= johnson_code;
            endcase
            valid_stage2          <= valid_stage1;
            flush_stage2          <= flush_stage1;
        end
    end

    // Stage 3: Register Johnson code output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            johnson_code_stage3 <= {WIDTH{1'b0}};
            valid_stage3        <= 1'b0;
            flush_stage3        <= 1'b1;
        end else begin
            johnson_code_stage3 <= johnson_code_stage2;
            valid_stage3        <= valid_stage2;
            flush_stage3        <= flush_stage2;
        end
    end

    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            johnson_code <= {WIDTH{1'b0}};
        end else if (valid_stage3 && !flush_stage3) begin
            johnson_code <= johnson_code_stage3;
        end
    end

endmodule