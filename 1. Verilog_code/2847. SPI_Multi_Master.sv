module SPI_Multi_Master #(
    parameter MASTERS = 3
)(
    input clk, rst_n,
    input [MASTERS-1:0] req,
    output reg [MASTERS-1:0] gnt,
    // Shared bus
    inout sclk, mosi, miso,
    output reg [MASTERS-1:0] cs_n
);

reg [1:0] state;
reg [3:0] timeout_cnt;
reg [MASTERS-1:0] last_grant;

// Define signals for bus driving
wire [MASTERS-1:0] master_sclk;
wire [MASTERS-1:0] master_mosi;
wire slave_miso;

localparam IDLE = 0, ARBITRATION = 1, TRANSFER = 2;

// Conflict detection logic
wire bus_busy = |(~cs_n);
wire collision = (|(gnt & req)) && bus_busy;

// Priority arbiter
always @(*) begin
    casex(req)
        3'b??1: gnt = 3'b001;
        3'b?10: gnt = 3'b010;
        3'b100: gnt = 3'b100;
        default: gnt = 3'b000;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        timeout_cnt <= 0;
        last_grant <= 0;
        cs_n <= {MASTERS{1'b1}};
    end else begin
        case(state)
        IDLE:
            if(|req && !bus_busy) begin
                state <= ARBITRATION;
                last_grant <= gnt;
                timeout_cnt <= 0;
            end
        ARBITRATION: begin
            timeout_cnt <= timeout_cnt + 1;
            if(timeout_cnt > 10)
                state <= TRANSFER;
        end
        TRANSFER:
            if(cs_n == {MASTERS{1'b1}})
                state <= IDLE;
        default:
            state <= IDLE;
        endcase
    end
end

// Simplified bus driving logic
assign sclk = gnt[0] ? master_sclk[0] :
              gnt[1] ? master_sclk[1] :
              gnt[2] ? master_sclk[2] : 1'bz;
              
assign mosi = gnt[0] ? master_mosi[0] :
              gnt[1] ? master_mosi[1] :
              gnt[2] ? master_mosi[2] : 1'bz;
              
// Placeholder assignments for simulation
assign master_sclk = 3'b000;
assign master_mosi = 3'b000;
assign slave_miso = miso;

// Chip select is active low when granted
always @(*) begin
    cs_n = ~gnt;
end
endmodule