//SystemVerilog
// Top-level module - Advanced Clock Gating Controller
module advanced_clock_gate #(
    parameter ENABLE_FILTER_WIDTH = 2,  // Parameterized filter width
    parameter USE_LATCH_BASED_GATING = 1 // Enable latch-based gating for better power
) (
    input  wire clk_in,
    input  wire rst_n,       // Reset signal (active low)
    input  wire enable,
    input  wire scan_mode,   // Test mode signal for DFT
    output wire clk_out
);
    // Internal signals
    wire enable_qualified;
    wire gating_control;
    
    // Instantiate the enable qualification submodule
    enable_processing u_enable_processor (
        .clk           (clk_in),
        .rst_n         (rst_n),
        .enable_in     (enable),
        .filter_width  (ENABLE_FILTER_WIDTH),
        .enable_out    (enable_qualified)
    );
    
    // Instantiate the gating control logic
    gating_control_logic u_gating_ctrl (
        .clk           (clk_in),
        .enable_in     (enable_qualified),
        .scan_mode     (scan_mode),
        .gating_ctrl   (gating_control)
    );
    
    // Instantiate technology-specific clock gating cell
    tech_clock_gating_cell #(
        .USE_LATCH_BASED (USE_LATCH_BASED_GATING)
    ) u_clk_gate (
        .clock_in       (clk_in),
        .enable_in      (gating_control),
        .scan_enable    (scan_mode),
        .gated_clock_out(clk_out)
    );
    
endmodule

// Module for enable signal processing with glitch filtering
module enable_processing #(
    parameter FILTER_WIDTH = 2
) (
    input  wire clk,
    input  wire rst_n,
    input  wire enable_in,
    input  wire [FILTER_WIDTH-1:0] filter_width,
    output reg  enable_out
);
    // Filter counter for debouncing the enable signal
    reg [FILTER_WIDTH-1:0] filter_counter;
    reg enable_filtered;
    
    // Filtering logic to prevent short pulses
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter_counter <= {FILTER_WIDTH{1'b0}};
            enable_filtered <= 1'b0;
        end else begin
            if (enable_in && !enable_filtered && (filter_counter < filter_width)) begin
                filter_counter <= filter_counter + 1'b1;
                if (filter_counter == filter_width - 1)
                    enable_filtered <= 1'b1;
            end else if (!enable_in && enable_filtered) begin
                filter_counter <= {FILTER_WIDTH{1'b0}};
                enable_filtered <= 1'b0;
            end
        end
    end
    
    // Output synchronization to prevent glitches
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            enable_out <= 1'b0;
        else
            enable_out <= enable_filtered;
    end
    
endmodule

// Module for gating control logic with timing optimization
module gating_control_logic (
    input  wire clk,
    input  wire enable_in,
    input  wire scan_mode,
    output reg  gating_ctrl
);
    // Register enable signal to create proper timing for clock gating
    // This prevents glitches when enable changes close to clock edge
    always @(posedge clk) begin
        gating_ctrl <= enable_in | scan_mode;
    end
    
endmodule

// Technology-specific clock gating cell implementation
module tech_clock_gating_cell #(
    parameter USE_LATCH_BASED = 1  // Use latch-based implementation for better power
) (
    input  wire clock_in,
    input  wire enable_in,
    input  wire scan_enable,
    output wire gated_clock_out
);
    // Internal signals
    wire enable_latched;
    wire final_enable;
    
    generate
        if (USE_LATCH_BASED) begin: latch_based_gating
            // Latch-based clock gating implementation (preferred for ASIC)
            // The latch is transparent when clock is low, holding the enable value
            reg enable_latch;
            
            always @(*) begin
                if (!clock_in)
                    enable_latch = enable_in;
            end
            
            assign enable_latched = enable_latch;
        end else begin: ff_based_gating
            // Flip-flop based implementation (alternative)
            reg enable_ff;
            
            always @(negedge clock_in) begin
                enable_ff <= enable_in;
            end
            
            assign enable_latched = enable_ff;
        end
    endgenerate
    
    // Final enable logic with scan mode bypass
    assign final_enable = enable_latched | scan_enable;
    
    // Actual clock gating implementation
    assign gated_clock_out = clock_in & final_enable;
    
endmodule