//SystemVerilog
module dram_ctrl_param #(
    parameter tRCD = 3,
    parameter tRP = 2,
    parameter tRAS = 5
)(
    input clk,
    input reset,
    input refresh_req,
    output reg refresh_ack
);

    localparam IDLE = 2'd0,
               REFRESH_DELAY = 2'd1,
               REFRESH_ACTIVE = 2'd2;
    
    reg [1:0] refresh_state;
    reg [7:0] refresh_counter;
    wire [7:0] next_counter;
    wire [7:0] counter_sub;
    wire [7:0] counter_mux;
    
    // Brent-Kung adder implementation
    wire [7:0] g, p, c;
    wire [7:0] g2, p2;
    wire [7:0] g4, p4;
    wire [7:0] g8, p8;
    
    // Generate and propagate signals
    assign g = refresh_counter & 8'hFF;
    assign p = refresh_counter ^ 8'hFF;
    
    // First level
    assign g2[0] = g[0];
    assign p2[0] = p[0];
    assign g2[1] = g[1] | (p[1] & g[0]);
    assign p2[1] = p[1] & p[0];
    
    // Second level
    assign g4[0] = g2[0];
    assign p4[0] = p2[0];
    assign g4[1] = g2[1];
    assign p4[1] = p2[1];
    assign g4[2] = g2[2] | (p2[2] & g2[0]);
    assign p4[2] = p2[2] & p2[0];
    assign g4[3] = g2[3] | (p2[3] & g2[1]);
    assign p4[3] = p2[3] & p2[1];
    
    // Third level
    assign g8[0] = g4[0];
    assign p8[0] = p4[0];
    assign g8[1] = g4[1];
    assign p8[1] = p4[1];
    assign g8[2] = g4[2];
    assign p8[2] = p4[2];
    assign g8[3] = g4[3];
    assign p8[3] = p4[3];
    assign g8[4] = g4[4] | (p4[4] & g4[0]);
    assign p8[4] = p4[4] & p4[0];
    assign g8[5] = g4[5] | (p4[5] & g4[1]);
    assign p8[5] = p4[5] & p4[1];
    assign g8[6] = g4[6] | (p4[6] & g4[2]);
    assign p8[6] = p4[6] & p4[2];
    assign g8[7] = g4[7] | (p4[7] & g4[3]);
    assign p8[7] = p4[7] & p4[3];
    
    // Final sum
    assign counter_sub = p ^ {g8[6:0], 1'b0};
    
    assign counter_mux = (refresh_counter == 0) ? refresh_counter : counter_sub;
    
    assign next_counter = (refresh_state == IDLE && refresh_req) ? tRCD :
                         (refresh_state == REFRESH_DELAY && refresh_counter == 0) ? tRAS :
                         counter_mux;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            refresh_state <= IDLE;
            refresh_ack <= 0;
            refresh_counter <= 0;
        end else begin
            if(refresh_state == IDLE && refresh_req) begin
                refresh_state <= REFRESH_DELAY;
                refresh_ack <= 0;
            end else if(refresh_state == REFRESH_DELAY && refresh_counter == 0) begin
                refresh_state <= REFRESH_ACTIVE;
            end else if(refresh_state == REFRESH_ACTIVE && refresh_counter == 0) begin
                refresh_state <= IDLE;
                refresh_ack <= 1;
            end else if(refresh_state != IDLE && refresh_state != REFRESH_DELAY && refresh_state != REFRESH_ACTIVE) begin
                refresh_state <= IDLE;
            end
            refresh_counter <= next_counter;
        end
    end
endmodule