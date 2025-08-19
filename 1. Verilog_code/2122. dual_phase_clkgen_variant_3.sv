//SystemVerilog
// Top-level module
module dual_phase_clkgen (
    input wire sys_clk,
    input wire async_rst,
    output wire clk_0deg,
    output wire clk_180deg
);
    // Internal signal declarations
    wire reset_sync;
    wire phase_toggle;
    wire phase_toggle_pre;
    
    // Reset synchronization sub-module
    reset_synchronizer u_reset_sync (
        .clk(sys_clk),
        .async_rst(async_rst),
        .sync_rst(reset_sync)
    );
    
    // Phase generation controller with pre-computed toggle value
    phase_controller u_phase_ctrl (
        .clk(sys_clk),
        .rst(reset_sync),
        .phase_toggle(phase_toggle),
        .phase_toggle_pre(phase_toggle_pre)
    );
    
    // Optimized clock output driver with retimed registers
    clock_output_driver u_clk_driver (
        .clk(sys_clk),
        .rst(reset_sync),
        .phase_toggle(phase_toggle),
        .phase_toggle_pre(phase_toggle_pre),
        .clk_0deg(clk_0deg),
        .clk_180deg(clk_180deg)
    );
    
endmodule

// Reset synchronization module
module reset_synchronizer (
    input wire clk,
    input wire async_rst,
    output reg sync_rst
);
    reg rst_meta;
    
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            rst_meta <= 1'b1;
            sync_rst <= 1'b1;
        end else begin
            rst_meta <= 1'b0;
            sync_rst <= rst_meta;
        end
    end
endmodule

// Phase controller module with pre-computed toggle value
module phase_controller (
    input wire clk,
    input wire rst,
    output reg phase_toggle,
    output wire phase_toggle_pre
);
    // Pre-compute the next toggle value
    assign phase_toggle_pre = ~phase_toggle;
    
    always @(posedge clk) begin
        if (rst) begin
            phase_toggle <= 1'b0;
        end else begin
            phase_toggle <= phase_toggle_pre;
        end
    end
endmodule

// Clock output driver module with retimed registers
module clock_output_driver (
    input wire clk,
    input wire rst,
    input wire phase_toggle,
    input wire phase_toggle_pre,
    output reg clk_0deg,
    output reg clk_180deg
);
    // Direct connections to outputs through registers
    // Registers have been pulled back before the combinational logic
    always @(posedge clk) begin
        if (rst) begin
            clk_0deg <= 1'b0;
            clk_180deg <= 1'b1;
        end else begin
            // Using pre-computed toggle values eliminates combinational
            // logic delay after the phase_controller registers
            clk_0deg <= phase_toggle_pre;
            clk_180deg <= phase_toggle;
        end
    end
endmodule