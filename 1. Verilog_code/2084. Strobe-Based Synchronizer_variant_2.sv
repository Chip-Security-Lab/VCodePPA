//SystemVerilog
module strobe_sync (
    input wire clk_a,
    input wire clk_b,
    input wire reset,
    input wire data_a,
    input wire strobe_a,
    output reg data_b,
    output reg strobe_b
);

    reg data_a_captured;
    reg toggle_a, toggle_a_meta, toggle_a_sync, toggle_a_delay;
    reg data_a_captured_meta, data_a_captured_sync, data_a_captured_delay;

    // Source domain
    always @(posedge clk_a) begin
        case (reset)
            1'b1: begin
                data_a_captured <= 1'b0;
                toggle_a <= 1'b0;
            end
            default: begin
                case (strobe_a)
                    1'b1: begin
                        data_a_captured <= data_a;
                        toggle_a <= ~toggle_a;
                    end
                    default: begin
                        data_a_captured <= data_a_captured;
                        toggle_a <= toggle_a;
                    end
                endcase
            end
        endcase
    end

    // Data capture synchronization (move the data_b register path before strobe_b generation)
    always @(posedge clk_b) begin
        case (reset)
            1'b1: begin
                data_a_captured_meta <= 1'b0;
                data_a_captured_sync <= 1'b0;
                data_a_captured_delay <= 1'b0;
            end
            default: begin
                data_a_captured_meta <= data_a_captured;
                data_a_captured_sync <= data_a_captured_meta;
                data_a_captured_delay <= data_a_captured_sync;
            end
        endcase
    end

    // Toggle synchronization and output strobe
    always @(posedge clk_b) begin
        case (reset)
            1'b1: begin
                toggle_a_meta <= 1'b0;
                toggle_a_sync <= 1'b0;
                toggle_a_delay <= 1'b0;
                strobe_b <= 1'b0;
            end
            default: begin
                toggle_a_meta <= toggle_a;
                toggle_a_sync <= toggle_a_meta;
                toggle_a_delay <= toggle_a_sync;
                strobe_b <= toggle_a_sync ^ toggle_a_delay;
            end
        endcase
    end

    // Output data_b register, now fully aligned with strobe_b
    always @(posedge clk_b) begin
        case (reset)
            1'b1: begin
                data_b <= 1'b0;
            end
            default: begin
                case (toggle_a_sync ^ toggle_a_delay)
                    1'b1: data_b <= data_a_captured_sync;
                    default: data_b <= data_b;
                endcase
            end
        endcase
    end

endmodule