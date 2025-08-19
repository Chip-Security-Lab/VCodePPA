//SystemVerilog
module circ_shift_reg #(
    parameter WIDTH = 12
)(
    input clk,
    input rstn,
    input en,
    input dir,
    input [WIDTH-1:0] load_val,
    input load_en,
    output reg [WIDTH-1:0] shifter_out
);

    // State encoding
    typedef enum logic [1:0] {
        RESET_STATE = 2'b00,
        LOAD_STATE  = 2'b01,
        SHIFT_STATE = 2'b10,
        HOLD_STATE  = 2'b11
    } state_t;

    // Buffer for next_state to reduce fanout
    reg [1:0] next_state_comb;
    reg [1:0] next_state_buf1;
    reg [1:0] next_state_buf2;

    // Buffer for shifter_out to reduce fanout
    reg [WIDTH-1:0] shifter_out_buf1;
    reg [WIDTH-1:0] shifter_out_buf2;

    // Next state combinational logic
    always @* begin
        if (!rstn)
            next_state_comb = RESET_STATE;
        else if (load_en)
            next_state_comb = LOAD_STATE;
        else if (en)
            next_state_comb = SHIFT_STATE;
        else
            next_state_comb = HOLD_STATE;
    end

    // First buffer stage for next_state
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            next_state_buf1 <= RESET_STATE;
        else
            next_state_buf1 <= next_state_comb;
    end

    // Second buffer stage for next_state (fanout reduction)
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            next_state_buf2 <= RESET_STATE;
        else
            next_state_buf2 <= next_state_buf1;
    end

    // Main register: buffered shifter_out
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shifter_out_buf1 <= {WIDTH{1'b0}};
        end else begin
            case (next_state_buf2)
                RESET_STATE: shifter_out_buf1 <= {WIDTH{1'b0}};
                LOAD_STATE:  shifter_out_buf1 <= load_val;
                SHIFT_STATE: shifter_out_buf1 <= dir ? {shifter_out_buf1[WIDTH-2:0], shifter_out_buf1[WIDTH-1]} :
                                                      {shifter_out_buf1[0], shifter_out_buf1[WIDTH-1:1]};
                HOLD_STATE:  shifter_out_buf1 <= shifter_out_buf1;
                default:     shifter_out_buf1 <= {WIDTH{1'b0}};
            endcase
        end
    end

    // Second buffer stage for shifter_out (fanout reduction)
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            shifter_out_buf2 <= {WIDTH{1'b0}};
        else
            shifter_out_buf2 <= shifter_out_buf1;
    end

    // Output register to drive output with minimal fanout load
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            shifter_out <= {WIDTH{1'b0}};
        else
            shifter_out <= shifter_out_buf2;
    end

endmodule