//SystemVerilog
// Top-level reset controller module with hierarchical structure
module multi_domain_reset_controller(
    input  wire clk,
    input  wire global_rst_n,
    input  wire por_n,
    input  wire ext_n,
    input  wire wdt_n,
    input  wire sw_n,
    output wire core_rst_n,
    output wire periph_rst_n,
    output wire mem_rst_n
);

    // Internal signals
    wire       any_reset_active;
    wire [1:0] reset_counter;

    // Detects if any reset source is asserted (active low)
    reset_condition_detector u_reset_condition_detector (
        .por_n         (por_n),
        .ext_n         (ext_n),
        .wdt_n         (wdt_n),
        .sw_n          (sw_n),
        .any_reset     (any_reset_active)
    );

    // Handles reset counter logic and generates reset_n signals for each domain
    reset_sequencer u_reset_sequencer (
        .clk           (clk),
        .global_rst_n  (global_rst_n),
        .any_reset     (any_reset_active),
        .reset_count   (reset_counter),
        .core_rst_n    (core_rst_n),
        .periph_rst_n  (periph_rst_n),
        .mem_rst_n     (mem_rst_n)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_condition_detector
// Description: Detects if any of the reset sources is asserted (active low)
// -----------------------------------------------------------------------------
module reset_condition_detector(
    input  wire por_n,
    input  wire ext_n,
    input  wire wdt_n,
    input  wire sw_n,
    output wire any_reset
);
    assign any_reset = ~por_n | ~ext_n | ~wdt_n | ~sw_n;
endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_sequencer
// Description: Counts clock cycles after all resets deasserted and
//              generates sequenced reset_n signals for core, peripheral, memory
// -----------------------------------------------------------------------------
module reset_sequencer(
    input  wire       clk,
    input  wire       global_rst_n,
    input  wire       any_reset,
    output reg  [1:0] reset_count,
    output reg        core_rst_n,
    output reg        periph_rst_n,
    output reg        mem_rst_n
);

    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            reset_count  <= 2'b00;
            core_rst_n   <= 1'b0;
            periph_rst_n <= 1'b0;
            mem_rst_n    <= 1'b0;
        end else begin
            case ({any_reset})
                1'b1: begin
                    reset_count  <= 2'b00;
                    core_rst_n   <= 1'b0;
                    periph_rst_n <= 1'b0;
                    mem_rst_n    <= 1'b0;
                end
                1'b0: begin
                    if (reset_count != 2'b11)
                        reset_count <= reset_count + 1;
                    else
                        reset_count <= reset_count;

                    case (reset_count)
                        2'b00: begin
                            core_rst_n   <= 1'b0;
                            periph_rst_n <= 1'b0;
                            mem_rst_n    <= 1'b0;
                        end
                        2'b01: begin
                            core_rst_n   <= 1'b1;
                            periph_rst_n <= 1'b0;
                            mem_rst_n    <= 1'b0;
                        end
                        2'b10: begin
                            core_rst_n   <= 1'b1;
                            periph_rst_n <= 1'b1;
                            mem_rst_n    <= 1'b0;
                        end
                        2'b11: begin
                            core_rst_n   <= 1'b1;
                            periph_rst_n <= 1'b1;
                            mem_rst_n    <= 1'b1;
                        end
                        default: begin
                            core_rst_n   <= 1'b0;
                            periph_rst_n <= 1'b0;
                            mem_rst_n    <= 1'b0;
                        end
                    endcase
                end
                default: begin
                    reset_count  <= 2'b00;
                    core_rst_n   <= 1'b0;
                    periph_rst_n <= 1'b0;
                    mem_rst_n    <= 1'b0;
                end
            endcase
        end
    end
endmodule