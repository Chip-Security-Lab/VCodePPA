//SystemVerilog
module SPI_Multi_Master #(
    parameter MASTERS = 3
)(
    input clk,
    input rst_n,
    input [MASTERS-1:0] req,
    output reg [MASTERS-1:0] gnt,
    // Shared bus
    inout sclk,
    inout mosi,
    inout miso,
    output reg [MASTERS-1:0] cs_n
);

reg [1:0] curr_state;
reg [3:0] timeout_counter;
reg [MASTERS-1:0] prev_grant;

// Define signals for bus driving
wire [MASTERS-1:0] master_sclk_bus;
wire [MASTERS-1:0] master_mosi_bus;
wire slave_miso_wire;

localparam IDLE = 2'd0,
           ARBITRATION = 2'd1,
           TRANSFER = 2'd2;

// Conflict detection logic
wire bus_is_busy = |(~cs_n);
wire has_collision = (|(gnt & req)) && bus_is_busy;

// Synchronous and combinational logic merged
always @(posedge clk or negedge rst_n) begin
    integer i;
    reg [MASTERS-1:0] grant_temp;
    if (!rst_n) begin
        curr_state <= IDLE;
        timeout_counter <= 4'd0;
        prev_grant <= {MASTERS{1'b0}};
        cs_n <= {MASTERS{1'b1}};
        gnt <= {MASTERS{1'b0}};
    end else begin
        // Priority grant logic (combinational section)
        grant_temp = {MASTERS{1'b0}};
        for (i = 0; i < MASTERS; i = i + 1) begin
            if (req[i] && (grant_temp == {MASTERS{1'b0}}))
                grant_temp[i] = 1'b1;
        end
        gnt <= grant_temp;

        // Chip select logic (combinational section)
        cs_n <= ~grant_temp;

        // FSM logic (sequential section)
        case (curr_state)
        IDLE: begin
            if (|req && !bus_is_busy) begin
                curr_state <= ARBITRATION;
                prev_grant <= grant_temp;
                timeout_counter <= 4'd0;
            end
        end
        ARBITRATION: begin
            timeout_counter <= timeout_counter + 4'd1;
            if (timeout_counter > 4'd10)
                curr_state <= TRANSFER;
        end
        TRANSFER: begin
            if (cs_n == {MASTERS{1'b1}})
                curr_state <= IDLE;
        end
        default: curr_state <= IDLE;
        endcase
    end
end

assign sclk = (gnt[0]) ? master_sclk_bus[0] :
              (gnt[1]) ? master_sclk_bus[1] :
              (gnt[2]) ? master_sclk_bus[2] : 1'bz;

assign mosi = (gnt[0]) ? master_mosi_bus[0] :
              (gnt[1]) ? master_mosi_bus[1] :
              (gnt[2]) ? master_mosi_bus[2] : 1'bz;

// Placeholder assignments for simulation
assign master_sclk_bus = {MASTERS{1'b0}};
assign master_mosi_bus = {MASTERS{1'b0}};
assign slave_miso_wire = miso;

endmodule