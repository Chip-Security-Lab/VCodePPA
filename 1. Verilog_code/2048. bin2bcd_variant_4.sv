//SystemVerilog
module bin2bcd #(parameter WIDTH = 8) (
    input wire clk,
    input wire load,
    input wire [WIDTH-1:0] bin_in,
    output reg [11:0] bcd_out, // 3 BCD digits
    output reg ready
);
    reg [WIDTH-1:0] bin_reg;
    reg [11:0] bcd_next;
    reg [3:0] state, state_next;
    reg ready_next;
    reg [11:0] bcd_reg;
    reg ready_reg;

    // Combinational logic for BCD conversion
    always @* begin
        bcd_next = bcd_reg;
        ready_next = ready_reg;
        state_next = state;
        case (ready_reg)
            1'b0: begin
                case (state)
                    0: begin
                        bcd_next = {bcd_reg[10:0], bin_reg[WIDTH-1]};
                        if (bcd_next[3:0] > 4)
                            bcd_next[3:0] = bcd_next[3:0] + 3;
                        if (bcd_next[7:4] > 4)
                            bcd_next[7:4] = bcd_next[7:4] + 3;
                        if (bcd_next[11:8] > 4)
                            bcd_next[11:8] = bcd_next[11:8] + 3;
                        ready_next = 1'b0;
                        state_next = state;
                    end
                    default: begin
                        if (state < WIDTH) begin
                            bcd_next = {bcd_reg[10:0], bin_reg[WIDTH-1]};
                            if (bcd_next[3:0] > 4)
                                bcd_next[3:0] = bcd_next[3:0] + 3;
                            if (bcd_next[7:4] > 4)
                                bcd_next[7:4] = bcd_next[7:4] + 3;
                            if (bcd_next[11:8] > 4)
                                bcd_next[11:8] = bcd_next[11:8] + 3;
                            ready_next = 1'b0;
                            state_next = state;
                        end
                        if (state == WIDTH) begin
                            ready_next = 1'b1;
                            state_next = state;
                        end
                    end
                endcase
            end
            1'b1: begin
                bcd_next = bcd_reg;
                ready_next = ready_reg;
                state_next = state;
            end
        endcase
    end

    // Sequential logic for state and registers
    always @(posedge clk) begin
        if (load) begin
            bin_reg <= bin_in;
            bcd_reg <= 12'b0;
            state <= 4'd0;
            ready_reg <= 1'b0;
        end else if (!ready_reg) begin
            case (state)
                default: begin
                    if (state < WIDTH) begin
                        bin_reg <= {bin_reg[WIDTH-2:0], 1'b0};
                        bcd_reg <= bcd_next;
                        state <= state + 1;
                        ready_reg <= 1'b0;
                    end else begin
                        bcd_reg <= bcd_next;
                        ready_reg <= ready_next;
                        state <= state;
                        bin_reg <= bin_reg;
                    end
                end
            endcase
        end
    end

    // Output registers
    always @(posedge clk) begin
        bcd_out <= bcd_reg;
        ready <= ready_reg;
    end
endmodule