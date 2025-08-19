//SystemVerilog
module i2c_master(
    input wire clk, rst_n,
    input wire [6:0] slave_addr,
    input wire [7:0] data_in,
    input wire rw, req,
    output reg [7:0] data_out,
    output reg ack, ack_error,
    inout wire scl, sda
);
    localparam IDLE=4'd0, START=4'd1, ADDR=4'd2, ACK1=4'd3,
               WRITE=4'd4, READ=4'd5, ACK2=4'd6, STOP=4'd7;
    reg [3:0] state, next;
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    reg scl_ena, sda_out;
    reg stretch;
    reg req_reg;
    
    // Kogge-Stone Adder signals
    wire [7:0] sum;
    wire [7:0] p, g;
    wire [7:0] g1, p1;
    wire [7:0] g2, p2;
    wire [7:0] g3, p3;
    wire [7:0] carry;
    
    // Generate and Propagate signals
    assign p = shift_reg ^ data_in;
    assign g = shift_reg & data_in;
    
    // First level
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    assign g1[4] = g[4] | (p[4] & g[3]);
    assign p1[4] = p[4] & p[3];
    assign g1[5] = g[5] | (p[5] & g[4]);
    assign p1[5] = p[5] & p[4];
    assign g1[6] = g[6] | (p[6] & g[5]);
    assign p1[6] = p[6] & p[5];
    assign g1[7] = g[7] | (p[7] & g[6]);
    assign p1[7] = p[7] & p[6];
    
    // Second level
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];
    
    // Third level
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign p3[4] = p2[4] & p2[0];
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign p3[5] = p2[5] & p2[1];
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign p3[6] = p2[6] & p2[2];
    assign g3[7] = g2[7] | (p2[7] & g2[3]);
    assign p3[7] = p2[7] & p2[3];
    
    // Final carry computation
    assign carry[0] = 1'b0;
    assign carry[1] = g3[0];
    assign carry[2] = g3[1];
    assign carry[3] = g3[2];
    assign carry[4] = g3[3];
    assign carry[5] = g3[4];
    assign carry[6] = g3[5];
    assign carry[7] = g3[6];
    
    // Sum calculation
    assign sum = p ^ carry;
    
    assign scl = scl_ena ? 1'bz : 1'b0;
    assign sda = sda_out ? 1'bz : 1'b0;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            shift_reg <= 8'd0;
            bit_count <= 3'd0;
            scl_ena <= 1'b0;
            sda_out <= 1'b1;
            ack <= 1'b0;
            ack_error <= 1'b0;
            stretch <= 1'b0;
            req_reg <= 1'b0;
        end else begin
            state <= next;
            req_reg <= req;
            
            case (state)
                IDLE: if (req && !req_reg) begin
                    shift_reg <= {slave_addr, rw};
                    ack <= 1'b1;
                end else begin
                    ack <= 1'b0;
                end
                START: begin scl_ena <= 1'b1; sda_out <= 1'b0; end
                ADDR: begin
                    sda_out <= shift_reg[7-bit_count];
                    if (bit_count < 3'd7) bit_count <= bit_count + 3'd1;
                    else bit_count <= 3'd0;
                end
                ACK1: begin
                    sda_out <= 1'b1;
                    ack_error <= sda;
                    if (rw && !ack_error) shift_reg <= 8'd0;
                    else if (!rw) shift_reg <= data_in;
                end
                WRITE: begin
                    sda_out <= shift_reg[7-bit_count];
                    if (bit_count < 3'd7) bit_count <= bit_count + 3'd1;
                    else bit_count <= 3'd0;
                end
                READ: begin
                    sda_out <= 1'b1;
                    shift_reg <= {shift_reg[6:0], sda};
                    if (bit_count < 3'd7) bit_count <= bit_count + 3'd1;
                    else begin
                        bit_count <= 3'd0;
                        data_out <= {shift_reg[6:0], sda};
                    end
                end
                ACK2: sda_out <= rw ? 1'b1 : 1'b0;
                STOP: begin sda_out <= 1'b0; scl_ena <= 1'b0; end
            endcase
        end
    
    always @(*)
        case(state)
            IDLE: next = (req && !req_reg) ? START : IDLE;
            START: next = ADDR;
            ADDR: next = (bit_count == 3'd7) ? ACK1 : ADDR;
            ACK1: next = (ack_error) ? STOP : (rw ? READ : WRITE);
            WRITE: next = (bit_count == 3'd7) ? ACK2 : WRITE;
            READ: next = (bit_count == 3'd7) ? ACK2 : READ;
            ACK2: next = STOP;
            STOP: next = IDLE;
            default: next = IDLE;
        endcase
endmodule