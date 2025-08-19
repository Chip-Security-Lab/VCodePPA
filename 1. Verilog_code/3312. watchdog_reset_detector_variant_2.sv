//SystemVerilog
module watchdog_reset_detector #(
    parameter TIMEOUT = 16'hFFFF
)(
    input  wire        clk,
    input  wire        enable,
    input  wire        watchdog_kick,
    input  wire        ext_reset_n,
    input  wire        pwr_reset_n,
    output reg         system_reset,
    output reg  [1:0]  reset_source
);

    reg  [15:0] watchdog_counter = 16'h0000;
    reg         pwr_reset_reg;
    reg         ext_reset_reg;
    reg         watchdog_timeout_reg;
    reg  [1:0]  reset_cause_reg;
    wire        pwr_reset_wire;
    wire        ext_reset_wire;
    wire        watchdog_timeout_wire;
    wire [1:0]  reset_cause_wire;

    assign pwr_reset_wire        = ~pwr_reset_n;
    assign ext_reset_wire        = ~ext_reset_n;
    assign watchdog_timeout_wire = (watchdog_counter >= TIMEOUT);

    always @(posedge clk) begin
        if (!enable)
            watchdog_counter <= 16'h0000;
        else if (watchdog_kick)
            watchdog_counter <= 16'h0000;
        else
            watchdog_counter <= watchdog_counter + 16'h0001;
    end

    always @(posedge clk) begin
        pwr_reset_reg        <= pwr_reset_wire;
        ext_reset_reg        <= ext_reset_wire;
        watchdog_timeout_reg <= watchdog_timeout_wire;
    end

    // Priority: Power reset > External reset > Watchdog timeout > None
    assign reset_cause_wire = (pwr_reset_reg)              ? 2'b00 : 
                              (ext_reset_reg)              ? 2'b01 : 
                              (watchdog_timeout_reg)       ? 2'b10 : 
                                                            2'b11;

    always @(posedge clk) begin
        reset_cause_reg <= reset_cause_wire;
    end

    always @(posedge clk) begin
        system_reset  <= pwr_reset_reg | ext_reset_reg | watchdog_timeout_reg;
        reset_source  <= reset_cause_reg;
    end

endmodule