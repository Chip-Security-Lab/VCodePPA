//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: debounced_reset
// Description: Top level module for debounced reset signal generation
///////////////////////////////////////////////////////////////////////////////
module debounced_reset #(
    parameter DEBOUNCE_COUNT = 3
)(
    input  wire clk,
    input  wire noisy_reset,
    output wire clean_reset
);
    // Internal signals
    wire reset_stable;
    wire count_reset;
    wire debounce_done;

    // Synchronizer submodule instantiation
    reset_synchronizer sync_inst (
        .clk          (clk),
        .noisy_reset  (noisy_reset),
        .sync_reset   (reset_stable)
    );

    // Edge detector submodule instantiation
    edge_detector edge_inst (
        .clk          (clk),
        .sync_reset   (reset_stable),
        .count_reset  (count_reset)
    );

    // Counter submodule instantiation
    debounce_counter #(
        .DEBOUNCE_COUNT (DEBOUNCE_COUNT)
    ) counter_inst (
        .clk          (clk),
        .count_reset  (count_reset),
        .debounce_done(debounce_done)
    );

    // Output register submodule instantiation
    output_register output_inst (
        .clk          (clk),
        .sync_reset   (reset_stable),
        .debounce_done(debounce_done),
        .clean_reset  (clean_reset)
    );
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: reset_synchronizer
// Description: Synchronizes the input reset signal to the clock domain
///////////////////////////////////////////////////////////////////////////////
module reset_synchronizer (
    input  wire clk,
    input  wire noisy_reset,
    output reg  sync_reset
);
    always @(posedge clk) begin
        sync_reset <= noisy_reset;
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: edge_detector
// Description: Detects changes in the synchronized reset signal
///////////////////////////////////////////////////////////////////////////////
module edge_detector (
    input  wire clk,
    input  wire sync_reset,
    output reg  count_reset
);
    reg sync_reset_prev;

    always @(posedge clk) begin
        sync_reset_prev <= sync_reset;
        count_reset <= (sync_reset != sync_reset_prev);
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: debounce_counter
// Description: Counts stable periods to confirm debounce completion
///////////////////////////////////////////////////////////////////////////////
module debounce_counter #(
    parameter DEBOUNCE_COUNT = 3
)(
    input  wire clk,
    input  wire count_reset,
    output reg  debounce_done
);
    reg [1:0] count;

    always @(posedge clk) begin
        case (count_reset)
            1'b1: begin
                count <= 0;
                debounce_done <= 1'b0;
            end
            1'b0: begin
                case (count < DEBOUNCE_COUNT)
                    1'b1: begin
                        count <= count + 1'b1;
                        debounce_done <= 1'b0;
                    end
                    1'b0: begin
                        debounce_done <= 1'b1;
                    end
                endcase
            end
        endcase
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: output_register
// Description: Updates the clean reset signal when debouncing is complete
///////////////////////////////////////////////////////////////////////////////
module output_register (
    input  wire clk,
    input  wire sync_reset,
    input  wire debounce_done,
    output reg  clean_reset
);
    always @(posedge clk) begin
        case (debounce_done)
            1'b1: clean_reset <= sync_reset;
            1'b0: clean_reset <= clean_reset; // Explicit hold value
        endcase
    end
endmodule