//SystemVerilog
module i2c_master(
    input wire clk, rst_n,
    input wire [6:0] slave_addr,
    input wire [7:0] data_in,
    input wire rw, start,
    output reg [7:0] data_out,
    output reg busy, ack_error,
    inout wire scl, sda
);
    localparam IDLE=4'd0, START=4'd1, ADDR=4'd2, ACK1=4'd3,
               WRITE=4'd4, READ=4'd5, ACK2=4'd6, STOP=4'd7;
    reg [3:0] state, next;
    reg [7:0] shift_reg, shift_reg_stage1, shift_reg_stage2;
    reg [2:0] bit_count, bit_count_stage1;
    reg scl_ena, sda_out;
    reg stretch;
    
    // Parallel prefix adder signals
    wire [7:0] g, p;
    wire [7:0] g_level1, p_level1;
    wire [7:0] g_level2, p_level2;
    wire [7:0] g_level3, p_level3;
    wire [7:0] sum;
    
    // Generate and propagate signals - Stage 1
    assign g = shift_reg_stage1 & data_in;
    assign p = shift_reg_stage1 ^ data_in;
    
    // First level - Stage 1
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    assign g_level1[2] = g[2] | (p[2] & g[1]);
    assign p_level1[2] = p[2] & p[1];
    assign g_level1[3] = g[3] | (p[3] & g[2]);
    assign p_level1[3] = p[3] & p[2];
    
    // Second level - Stage 2
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[2] = p_level1[2] & p_level1[0];
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[3] = p_level1[3] & p_level1[1];
    
    // Third level - Stage 3
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3];
    assign p_level3[3] = p_level2[3];
    
    // Final sum calculation - Stage 4
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ g_level3[0];
    assign sum[2] = p[2] ^ g_level3[1];
    assign sum[3] = p[3] ^ g_level3[2];
    assign sum[4] = p[4] ^ g_level3[3];
    assign sum[5] = p[5] ^ g_level3[4];
    assign sum[6] = p[6] ^ g_level3[5];
    assign sum[7] = p[7] ^ g_level3[6];
    
    assign scl = scl_ena ? 1'bz : 1'b0;
    assign sda = sda_out ? 1'bz : 1'b0;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            shift_reg_stage1 <= 8'd0;
            bit_count_stage1 <= 3'd0;
            scl_ena <= 1'b0;
            sda_out <= 1'b1;
            busy <= 1'b0;
            ack_error <= 1'b0;
            stretch <= 1'b0;
        end else begin
            state <= next;
            busy <= (state != IDLE);
            
            case (state)
                IDLE: begin
                    if (start) begin
                        shift_reg_stage1 <= {slave_addr, rw};
                    end
                end
                START: begin
                    scl_ena <= 1'b1;
                    sda_out <= 1'b0;
                end
                ADDR: begin
                    sda_out <= shift_reg_stage1[7-bit_count_stage1];
                    if (bit_count_stage1 < 3'd7) begin
                        bit_count_stage1 <= bit_count_stage1 + 3'd1;
                    end else begin
                        bit_count_stage1 <= 3'd0;
                    end
                end
                ACK1: begin
                    sda_out <= 1'b1;
                    ack_error <= sda;
                end
                WRITE: begin
                    sda_out <= shift_reg_stage1[7-bit_count_stage1];
                    if (bit_count_stage1 < 3'd7) begin
                        bit_count_stage1 <= bit_count_stage1 + 3'd1;
                    end else begin
                        bit_count_stage1 <= 3'd0;
                    end
                end
                READ: begin
                    sda_out <= 1'b1;
                end
                ACK2: begin
                    if (rw) begin
                        sda_out <= 1'b1;
                    end else begin
                        sda_out <= 1'b0;
                    end
                end
                STOP: begin
                    sda_out <= 1'b0;
                    scl_ena <= 1'b0;
                end
            endcase
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 8'd0;
            bit_count <= 3'd0;
        end else begin
            case (state)
                ACK1: begin
                    if (rw && !ack_error) begin
                        shift_reg_stage2 <= 8'd0;
                    end else if (!rw) begin
                        shift_reg_stage2 <= sum;
                    end
                end
                READ: begin
                    shift_reg_stage2 <= {shift_reg_stage1[6:0], sda};
                    if (bit_count_stage1 < 3'd7) begin
                        bit_count <= bit_count_stage1 + 3'd1;
                    end else begin
                        bit_count <= 3'd0;
                        data_out <= {shift_reg_stage1[6:0], sda};
                    end
                end
            endcase
        end
    end
    
    always @(*) begin
        case(state)
            IDLE: begin
                if (start) begin
                    next = START;
                end else begin
                    next = IDLE;
                end
            end
            START: begin
                next = ADDR;
            end
            ADDR: begin
                if (bit_count_stage1 == 3'd7) begin
                    next = ACK1;
                end else begin
                    next = ADDR;
                end
            end
            ACK1: begin
                if (ack_error) begin
                    next = STOP;
                end else begin
                    if (rw) begin
                        next = READ;
                    end else begin
                        next = WRITE;
                    end
                end
            end
            WRITE: begin
                if (bit_count_stage1 == 3'd7) begin
                    next = ACK2;
                end else begin
                    next = WRITE;
                end
            end
            READ: begin
                if (bit_count == 3'd7) begin
                    next = ACK2;
                end else begin
                    next = READ;
                end
            end
            ACK2: begin
                next = STOP;
            end
            STOP: begin
                next = IDLE;
            end
            default: begin
                next = IDLE;
            end
        endcase
    end
endmodule