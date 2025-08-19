//SystemVerilog
module cdc_mux (
    input clk_src, clk_dst, rst_n,
    input [15:0] data_a, data_b,
    input select,
    output reg [15:0] synced_out,
    output reg req,
    input ack
);
    wire [15:0] mux_out;
    reg req_d;
    reg [15:0] data_hold;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam REQUEST = 2'b01;
    localparam WAIT_ACK = 2'b10;
    
    mux_selector u_mux_selector (
        .data_a(data_a),
        .data_b(data_b),
        .select(select),
        .mux_out(mux_out)
    );
    
    always @(posedge clk_src or negedge rst_n) begin
        if (!rst_n) begin
            req <= 1'b0;
            req_d <= 1'b0;
            data_hold <= 16'h0;
            state <= IDLE;
        end else begin
            req_d <= req;
            case (state)
                IDLE: begin
                    if (!req_d && !req) begin
                        req <= 1'b1;
                        data_hold <= mux_out;
                        state <= REQUEST;
                    end
                end
                REQUEST: begin
                    if (ack) begin
                        req <= 1'b0;
                        state <= WAIT_ACK;
                    end
                end
                WAIT_ACK: begin
                    if (!ack) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    synchronizer u_synchronizer (
        .clk_dst(clk_dst),
        .rst_n(rst_n),
        .data_in(data_hold),
        .data_out(synced_out)
    );
endmodule

module mux_selector (
    input [15:0] data_a, data_b,
    input select,
    output [15:0] mux_out
);
    parameter DATA_WIDTH = 16;
    assign mux_out = select ? data_b : data_a;
endmodule

module synchronizer (
    input clk_dst,
    input rst_n,
    input [15:0] data_in,
    output reg [15:0] data_out
);
    parameter DATA_WIDTH = 16;
    parameter SYNC_STAGES = 2;
    
    reg [DATA_WIDTH-1:0] sync_stage [SYNC_STAGES-1:0];
    integer i;
    
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= {DATA_WIDTH{1'b0}};
            end
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            sync_stage[0] <= data_in;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
            data_out <= sync_stage[SYNC_STAGES-1];
        end
    end
endmodule