//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: sr_latch_top.v
// Description: Top-level module for SR latch implementation with improved
//              pipelined datapath architecture
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module sr_latch_top (
    input  wire        clk,       // Clock input
    input  wire        rst_n,     // Active-low reset
    input  wire        s,         // Set input
    input  wire        r,         // Reset input
    output wire        q          // Output state
);

    // Pipeline stage signals for improved datapath organization
    wire        s_conditioned_stage1;
    wire        r_conditioned_stage1;
    wire        set_active_stage1;
    wire        reset_active_stage1;
    reg         set_active_stage2;
    reg         reset_active_stage2;
    reg         latch_state_stage2;
    reg         latch_state_stage3;
    
    // Stage 1: Input conditioning with improved isolation
    sr_input_conditioning u_input_conditioning (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_in          (s),
        .r_in          (r),
        .s_conditioned (s_conditioned_stage1),
        .r_conditioned (r_conditioned_stage1),
        .set_active    (set_active_stage1),
        .reset_active  (reset_active_stage1)
    );
    
    // Pipeline register between conditioning and core logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            set_active_stage2   <= 1'b0;
            reset_active_stage2 <= 1'b0;
        end else begin
            set_active_stage2   <= set_active_stage1;
            reset_active_stage2 <= reset_active_stage1;
        end
    end
    
    // Stage 2: Core latch operation with registered inputs
    sr_latch_core u_latch_core (
        .clk           (clk),
        .rst_n         (rst_n),
        .set_active    (set_active_stage2),
        .reset_active  (reset_active_stage2),
        .q_out         (latch_state_stage2)
    );
    
    // Pipeline register between core logic and output buffer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latch_state_stage3 <= 1'b0;
        end else begin
            latch_state_stage3 <= latch_state_stage2;
        end
    end
    
    // Stage 3: Output buffering with registered input
    sr_output_buffer u_output_buffer (
        .clk           (clk),
        .rst_n         (rst_n),
        .latch_state   (latch_state_stage3),
        .q             (q)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: sr_input_conditioning.v
// Description: Pipelined input signal conditioning module
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module sr_input_conditioning (
    input  wire        clk,           // Clock input
    input  wire        rst_n,         // Active-low reset
    input  wire        s_in,          // Raw set input
    input  wire        r_in,          // Raw reset input
    output reg         s_conditioned, // Registered set signal
    output reg         r_conditioned, // Registered reset signal
    output wire        set_active,    // Conditioned set signal
    output wire        reset_active   // Conditioned reset signal
);

    // Input registration for better timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_conditioned <= 1'b0;
            r_conditioned <= 1'b0;
        end else begin
            s_conditioned <= s_in;
            r_conditioned <= r_in;
        end
    end

    // Improved input conditioning logic with priority resolution
    assign set_active = s_conditioned && !r_conditioned;
    assign reset_active = !s_conditioned && r_conditioned;

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: sr_latch_core.v
// Description: Core SR latch functionality with synchronous behavior
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module sr_latch_core (
    input  wire        clk,           // Clock input
    input  wire        rst_n,         // Active-low reset
    input  wire        set_active,    // Active set signal
    input  wire        reset_active,  // Active reset signal
    output reg         q_out          // Latch state output
);

    // Synchronous SR latch with priority reset for improved stability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_out <= 1'b0;
        end else if (reset_active) begin
            q_out <= 1'b0;
        end else if (set_active) begin
            q_out <= 1'b1;
        end
        // Hold state when neither set nor reset is active
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: sr_output_buffer.v
// Description: Output buffering with drive strength control
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module sr_output_buffer (
    input  wire        clk,           // Clock input
    input  wire        rst_n,         // Active-low reset
    input  wire        latch_state,   // Internal latch state
    output reg         q              // Registered buffered output
);

    // Output registration for improved drive capability and timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
        end else begin
            q <= latch_state;
        end
    end

endmodule