//SystemVerilog
// SystemVerilog
// State machine module with improved data flow
module AXIStreamStateMachine (
    input clk,
    input rst_n,
    input tvalid,
    input tlast,
    output reg tready,
    output reg [1:0] state
);

    // State encoding
    localparam IDLE = 2'b00;
    localparam VALID = 2'b01;

    always @(posedge clk) begin
        if (!rst_n) begin
            tready <= 0;
            state <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    if (tvalid) begin
                        tready <= 1;
                        state <= VALID;
                    end
                end
                VALID: begin
                    if (tlast) begin
                        tready <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule

// Top level module with structured data path
module AXIStreamBridge #(
    parameter TDATA_W = 32
)(
    input clk,
    input rst_n,
    input [TDATA_W-1:0] tdata,
    input tvalid,
    input tlast,
    output tready
);

    wire [1:0] state;

    // Instantiate state machine
    AXIStreamStateMachine state_machine (
        .clk(clk),
        .rst_n(rst_n),
        .tvalid(tvalid),
        .tlast(tlast),
        .tready(tready),
        .state(state)
    );

endmodule