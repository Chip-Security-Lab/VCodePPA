//SystemVerilog
module binary_to_bcd #(
    parameter WIDTH = 8,
    parameter DIGITS = 3
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [WIDTH-1:0] binary_in,
    output reg [4*DIGITS-1:0] bcd_out,
    output reg done
);

    localparam IDLE      = 2'd0;
    localparam PROCESS   = 2'd1;
    localparam FINISH    = 2'd2;

    reg [1:0] state, next_state;

    reg [WIDTH-1:0] bin_reg, bin_next;
    reg [4*DIGITS-1:0] bcd_reg, bcd_next;
    reg [$clog2(WIDTH+1)-1:0] i_reg, i_next;
    reg [$clog2(DIGITS+1)-1:0] j_reg, j_next;
    reg [4*DIGITS-1:0] bcd_shifted, bcd_adjusted;
    reg adjust_flag, adjust_flag_next;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            bin_reg  <= {WIDTH{1'b0}};
            bcd_reg  <= {4*DIGITS{1'b0}};
            i_reg    <= {($clog2(WIDTH+1)){1'b0}};
            j_reg    <= {($clog2(DIGITS+1)){1'b0}};
            adjust_flag <= 1'b0;
            done     <= 1'b0;
        end else begin
            state    <= next_state;
            bin_reg  <= bin_next;
            bcd_reg  <= bcd_next;
            i_reg    <= i_next;
            j_reg    <= j_next;
            adjust_flag <= adjust_flag_next;
            if (next_state == FINISH)
                done <= 1'b1;
            else if (next_state == IDLE)
                done <= 1'b0;
        end
    end

    // Next state logic
    always @* begin
        // Defaults
        next_state = state;
        bin_next = bin_reg;
        bcd_next = bcd_reg;
        i_next = i_reg;
        j_next = j_reg;
        adjust_flag_next = adjust_flag;

        case (state)
            IDLE: begin
                if (start) begin
                    next_state = PROCESS;
                    bin_next = binary_in;
                    bcd_next = {4*DIGITS{1'b0}};
                    i_next = 0;
                    j_next = 0;
                    adjust_flag_next = 1'b0;
                end
            end

            PROCESS: begin
                // 1. Adjust BCD digits if necessary
                if (!adjust_flag) begin
                    if (j_reg < DIGITS) begin
                        if (bcd_reg[4*j_reg +: 4] > 4) begin
                            bcd_next = bcd_reg;
                            bcd_next[4*j_reg +: 4] = bcd_reg[4*j_reg +: 4] + 3;
                        end
                        j_next = j_reg + 1;
                        adjust_flag_next = 1'b0;
                    end else begin
                        // Finished adjusting all digits, do shift
                        adjust_flag_next = 1'b1;
                        j_next = 0;
                    end
                end else begin
                    // 2. Shift and load next bit
                    bcd_shifted = bcd_reg << 1;
                    bcd_shifted[0] = bin_reg[WIDTH-1];
                    bcd_next = bcd_shifted;
                    bin_next = bin_reg << 1;
                    i_next = i_reg + 1;
                    adjust_flag_next = 1'b0;
                    if (i_reg + 1 < WIDTH) begin
                        next_state = PROCESS;
                    end else begin
                        next_state = FINISH;
                    end
                end
            end

            FINISH: begin
                bcd_next = bcd_reg;
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_out <= {4*DIGITS{1'b0}};
        end else if (state == FINISH) begin
            bcd_out <= bcd_reg;
        end
    end

endmodule