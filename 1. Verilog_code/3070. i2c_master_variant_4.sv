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
    
    reg [3:0] state, next_state;
    reg [7:0] shift_reg, shift_reg_next;
    reg [2:0] bit_count, bit_count_next;
    reg scl_ena, scl_ena_next;
    reg sda_out, sda_out_next;
    reg stretch;
    reg busy_next, ack_error_next;
    reg [7:0] data_out_next;
    
    // 组合逻辑部分
    assign scl = scl_ena ? 1'bz : 1'b0;
    assign sda = sda_out ? 1'bz : 1'b0;
    
    // 状态转换组合逻辑
    always @(*) begin
        case(state)
            IDLE: next_state = start ? START : IDLE;
            START: next_state = ADDR;
            ADDR: next_state = (bit_count == 3'd7) ? ACK1 : ADDR;
            ACK1: next_state = (ack_error) ? STOP : (rw ? READ : WRITE);
            WRITE: next_state = (bit_count == 3'd7) ? ACK2 : WRITE;
            READ: next_state = (bit_count == 3'd7) ? ACK2 : READ;
            ACK2: next_state = STOP;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 输出组合逻辑
    always @(*) begin
        shift_reg_next = shift_reg;
        bit_count_next = bit_count;
        scl_ena_next = scl_ena;
        sda_out_next = sda_out;
        busy_next = (state != IDLE);
        ack_error_next = ack_error;
        data_out_next = data_out;

        case (state)
            IDLE: if (start) shift_reg_next = {slave_addr, rw};
            START: begin 
                scl_ena_next = 1'b1; 
                sda_out_next = 1'b0; 
            end
            ADDR: begin
                sda_out_next = shift_reg[7-bit_count];
                if (bit_count < 3'd7) 
                    bit_count_next = bit_count + 3'd1;
                else 
                    bit_count_next = 3'd0;
            end
            ACK1: begin
                sda_out_next = 1'b1;
                ack_error_next = sda;
                if (rw && !ack_error) 
                    shift_reg_next = 8'd0;
                else if (!rw) 
                    shift_reg_next = data_in;
            end
            WRITE: begin
                sda_out_next = shift_reg[7-bit_count];
                if (bit_count < 3'd7) 
                    bit_count_next = bit_count + 3'd1;
                else 
                    bit_count_next = 3'd0;
            end
            READ: begin
                sda_out_next = 1'b1;
                shift_reg_next = {shift_reg[6:0], sda};
                if (bit_count < 3'd7) 
                    bit_count_next = bit_count + 3'd1;
                else begin
                    bit_count_next = 3'd0;
                    data_out_next = {shift_reg[6:0], sda};
                end
            end
            ACK2: sda_out_next = rw ? 1'b1 : 1'b0;
            STOP: begin 
                sda_out_next = 1'b0; 
                scl_ena_next = 1'b0; 
            end
        endcase
    end
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            shift_reg <= 8'd0;
            bit_count <= 3'd0;
            scl_ena <= 1'b0;
            sda_out <= 1'b1;
            busy <= 1'b0;
            ack_error <= 1'b0;
            stretch <= 1'b0;
            data_out <= 8'd0;
        end else begin
            state <= next_state;
            shift_reg <= shift_reg_next;
            bit_count <= bit_count_next;
            scl_ena <= scl_ena_next;
            sda_out <= sda_out_next;
            busy <= busy_next;
            ack_error <= ack_error_next;
            data_out <= data_out_next;
        end
    end
endmodule