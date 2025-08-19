//SystemVerilog
module I2C_Controller #(
    parameter ADDR_WIDTH = 7
)(
    input clk, rst_n,
    input start,
    input [ADDR_WIDTH-1:0] dev_addr,
    input [7:0] data_tx,
    output reg [7:0] data_rx,
    output reg ack_error,
    inout sda,
    inout scl
);

    localparam [6:0] IDLE  = 7'b0000001, 
                     START = 7'b0000010, 
                     ADDR  = 7'b0000100, 
                     ACK1  = 7'b0001000, 
                     DATA  = 7'b0010000, 
                     ACK2  = 7'b0100000, 
                     STOP  = 7'b1000000;
                     
    reg [6:0] current_state, next_state;
    reg scl_out;
    reg [3:0] bit_counter;
    reg [7:0] shift_reg;
    reg rw_bit;
    reg sda_oe;
    
    assign sda = sda_oe ? 1'b0 : 1'bz;
    assign scl = scl_out ? 1'bz : 1'b0;
    
    // 优化比较逻辑
    wire bit_count_eq_8 = &bit_counter[3:0];
    wire is_read_mode = rw_bit;
    wire scl_low = ~scl_out;
    wire scl_high = scl_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            scl_out <= 1'b1;
            sda_oe <= 1'b0;
            bit_counter <= 4'b0;
            shift_reg <= 8'b0;
            data_rx <= 8'b0;
            ack_error <= 1'b0;
            rw_bit <= 1'b0;
        end else begin
            current_state <= next_state;
            
            case(1'b1)
                current_state[0]: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0;
                    if (start) begin
                        shift_reg <= {dev_addr, rw_bit};
                    end
                end
                
                current_state[1]: begin
                    sda_oe <= 1'b1;
                    scl_out <= 1'b1;
                end
                
                current_state[2]: begin
                    if (!bit_count_eq_8) begin
                        if (scl_low) begin
                            sda_oe <= ~shift_reg[7];
                            scl_out <= 1'b1;
                        end else begin
                            scl_out <= 1'b0;
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_counter <= bit_counter + 4'b1;
                        end
                    end
                end
                
                current_state[3]: begin
                    if (scl_low) begin
                        sda_oe <= 1'b0;
                        scl_out <= 1'b1;
                    end else begin
                        ack_error <= sda;
                        scl_out <= 1'b0;
                        bit_counter <= 4'b0;
                        shift_reg <= is_read_mode ? shift_reg : data_tx;
                    end
                end
                
                current_state[4]: begin
                    if (!bit_count_eq_8) begin
                        if (scl_low) begin
                            sda_oe <= is_read_mode ? 1'b0 : ~shift_reg[7];
                            scl_out <= 1'b1;
                        end else begin
                            scl_out <= 1'b0;
                            if (is_read_mode) 
                                shift_reg <= {shift_reg[6:0], sda};
                            else 
                                shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_counter <= bit_counter + 4'b1;
                        end
                    end
                end
                
                current_state[5]: begin
                    if (scl_low) begin
                        sda_oe <= is_read_mode ? 1'b1 : 1'b0;
                        scl_out <= 1'b1;
                    end else begin
                        if (!is_read_mode) ack_error <= sda;
                        scl_out <= 1'b0;
                        data_rx <= shift_reg;
                    end
                end
                
                current_state[6]: begin
                    if (scl_low) begin
                        sda_oe <= 1'b1;
                        scl_out <= 1'b1;
                    end else begin
                        sda_oe <= 1'b0;
                    end
                end
                
                default: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(1'b1)
            current_state[0]: next_state = start ? START : IDLE;
            current_state[1]: next_state = ADDR;
            current_state[2]: next_state = bit_count_eq_8 ? ACK1 : ADDR;
            current_state[3]: next_state = DATA;
            current_state[4]: next_state = bit_count_eq_8 ? ACK2 : DATA;
            current_state[5]: next_state = STOP;
            current_state[6]: next_state = IDLE;
            default:          next_state = IDLE;
        endcase
    end
endmodule