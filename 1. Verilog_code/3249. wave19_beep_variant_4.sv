//SystemVerilog
module wave19_beep #(
    parameter BEEP_ON  = 50,
    parameter BEEP_OFF = 50,
    parameter WIDTH    = 8
)(
    input  wire clk,
    input  wire rst,
    output reg  beep_out
);

    // Stage 1: Counter increment and range compare
    reg [WIDTH-1:0] cnt_stage1;
    reg             state_stage1;
    reg             beep_on_hit_stage1;
    reg             beep_off_hit_stage1;

    // Stage 2: Pipeline registers
    reg [WIDTH-1:0] cnt_stage2;
    reg             state_stage2;
    reg             beep_on_hit_stage2;
    reg             beep_off_hit_stage2;

    // Stage 3: Next state logic
    reg             next_state_stage3;
    reg [WIDTH-1:0] next_cnt_stage3;
    reg             next_beep_out_stage3;

    // Stage 1: Efficient range-based compare
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage1         <= {WIDTH{1'b0}};
            state_stage1       <= 1'b0;
            beep_on_hit_stage1 <= 1'b0;
            beep_off_hit_stage1<= 1'b0;
        end else begin
            if ((!state_stage1 && cnt_stage1 == BEEP_ON) ||
                (state_stage1 && cnt_stage1 == BEEP_OFF)) begin
                cnt_stage1 <= {WIDTH{1'b0}};
            end else begin
                cnt_stage1 <= cnt_stage1 + 1'b1;
            end
            state_stage1 <= state_stage1;

            beep_on_hit_stage1  <= ~state_stage1 && cnt_stage1 == BEEP_ON;
            beep_off_hit_stage1 <=  state_stage1 && cnt_stage1 == BEEP_OFF;
        end
    end

    // Stage 2: Pipeline control and state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage2         <= {WIDTH{1'b0}};
            state_stage2       <= 1'b0;
            beep_on_hit_stage2 <= 1'b0;
            beep_off_hit_stage2<= 1'b0;
        end else begin
            cnt_stage2         <= cnt_stage1;
            state_stage2       <= state_stage1;
            beep_on_hit_stage2 <= beep_on_hit_stage1;
            beep_off_hit_stage2<= beep_off_hit_stage1;
        end
    end

    // Stage 3: Optimized combinational next state logic
    always @(*) begin
        next_state_stage3    = state_stage2;
        next_cnt_stage3      = cnt_stage2;
        next_beep_out_stage3 = beep_out;

        if (beep_on_hit_stage2) begin
            next_state_stage3    = 1'b1;
            next_cnt_stage3      = {WIDTH{1'b0}};
            next_beep_out_stage3 = 1'b0;
        end else if (beep_off_hit_stage2) begin
            next_state_stage3    = 1'b0;
            next_cnt_stage3      = {WIDTH{1'b0}};
            next_beep_out_stage3 = 1'b1;
        end
    end

    // Final pipeline stage: register output/state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage1 <= 1'b0;
            cnt_stage1   <= {WIDTH{1'b0}};
            beep_out     <= 1'b0;
        end else begin
            state_stage1 <= next_state_stage3;
            cnt_stage1   <= next_cnt_stage3;
            beep_out     <= next_beep_out_stage3;
        end
    end

endmodule