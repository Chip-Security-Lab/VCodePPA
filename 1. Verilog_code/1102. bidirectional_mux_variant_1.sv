//SystemVerilog
// Top-level module: Pipelined and Structured Bidirectional Mux
module bidirectional_mux (
    inout wire [7:0] port_a,         // Bidirectional port A
    inout wire [7:0] port_b,         // Bidirectional port B
    inout wire [7:0] common_port,    // Common bidirectional port
    input wire        direction,     // Data flow direction: 0=A->common, 1=B->common
    input wire        active,        // Active enable signal
    input wire        clk,           // Clock for pipelining
    input wire        rst_n          // Active low reset
);

    // Pipeline Stage 1: Capture and register input signals
    wire [7:0] port_a_in;
    wire [7:0] port_b_in;
    wire [7:0] common_port_in;

    assign port_a_in     = port_a;
    assign port_b_in     = port_b;
    assign common_port_in= common_port;

    // Stage 1 registers
    reg [7:0] port_a_stage1;
    reg [7:0] port_b_stage1;
    reg [7:0] common_port_stage1;
    reg       direction_stage1;
    reg       active_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            port_a_stage1        <= 8'd0;
            port_b_stage1        <= 8'd0;
            common_port_stage1   <= 8'd0;
            direction_stage1     <= 1'b0;
            active_stage1        <= 1'b0;
        end else begin
            port_a_stage1        <= port_a_in;
            port_b_stage1        <= port_b_in;
            common_port_stage1   <= common_port_in;
            direction_stage1     <= direction;
            active_stage1        <= active;
        end
    end

    // Pipeline Stage 2: Control logic and data path selection
    wire a_drive_enable_stage2;
    wire b_drive_enable_stage2;
    wire common_drive_enable_stage2;

    mux_ctrl u_mux_ctrl (
        .direction           (direction_stage1),
        .active              (active_stage1),
        .a_drive_en          (a_drive_enable_stage2),
        .b_drive_en          (b_drive_enable_stage2),
        .common_drive_en     (common_drive_enable_stage2)
    );

    wire [7:0] mux_data_to_common_stage2;
    data_sel u_data_sel (
        .port_a              (port_a_stage1),
        .port_b              (port_b_stage1),
        .direction           (direction_stage1),
        .mux_to_common       (mux_data_to_common_stage2)
    );

    // Pipeline registers for stage 2 outputs
    reg [7:0] mux_data_to_common_stage3;
    reg [7:0] common_port_stage2;
    reg       a_drive_enable_stage3;
    reg       b_drive_enable_stage3;
    reg       common_drive_enable_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_data_to_common_stage3   <= 8'd0;
            common_port_stage2          <= 8'd0;
            a_drive_enable_stage3       <= 1'b0;
            b_drive_enable_stage3       <= 1'b0;
            common_drive_enable_stage3  <= 1'b0;
        end else begin
            mux_data_to_common_stage3   <= mux_data_to_common_stage2;
            common_port_stage2          <= common_port_stage1;
            a_drive_enable_stage3       <= a_drive_enable_stage2;
            b_drive_enable_stage3       <= b_drive_enable_stage2;
            common_drive_enable_stage3  <= common_drive_enable_stage2;
        end
    end

    // Stage 3: Structured bidirectional buffers for output driving
    bidir_buffer u_bidir_buf_a (
        .data_in        (common_port_stage2),
        .drive_en       (a_drive_enable_stage3),
        .bidir          (port_a)
    );

    bidir_buffer u_bidir_buf_b (
        .data_in        (common_port_stage2),
        .drive_en       (b_drive_enable_stage3),
        .bidir          (port_b)
    );

    bidir_buffer u_bidir_buf_common (
        .data_in        (mux_data_to_common_stage3),
        .drive_en       (common_drive_enable_stage3),
        .bidir          (common_port)
    );

endmodule

//-----------------------------------------------------------------------------
// mux_ctrl: Control logic for enable signals (1 pipeline stage delay)
//-----------------------------------------------------------------------------
module mux_ctrl (
    input  wire direction,           // Data flow direction
    input  wire active,              // Active enable
    output wire a_drive_en,          // Enable for driving port_a
    output wire b_drive_en,          // Enable for driving port_b
    output wire common_drive_en      // Enable for driving common_port
);
    assign a_drive_en      = active & ~direction;
    assign b_drive_en      = active &  direction;
    assign common_drive_en = active;
endmodule

//-----------------------------------------------------------------------------
// data_sel: Data selection logic for driving common_port (1 pipeline stage delay)
//-----------------------------------------------------------------------------
module data_sel (
    input  wire [7:0] port_a,        // Data from port_a
    input  wire [7:0] port_b,        // Data from port_b
    input  wire       direction,     // Direction select
    output wire [7:0] mux_to_common  // Data to drive on common_port
);
    assign mux_to_common = direction ? port_a : port_b;
endmodule

//-----------------------------------------------------------------------------
// bidir_buffer: Bidirectional buffer with tristate control
//-----------------------------------------------------------------------------
module bidir_buffer (
    input  wire [7:0] data_in,       // Data to drive onto bidir port
    input  wire       drive_en,      // Enable to drive data
    inout  wire [7:0] bidir          // Bidirectional port
);
    assign bidir = drive_en ? data_in : 8'bz;
endmodule