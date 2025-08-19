//SystemVerilog
module MIPI_CommandParser #(
    parameter CMD_TABLE_SIZE = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] cmd_byte,
    input wire cmd_valid,
    output reg [15:0] param_reg,
    output reg cmd_ready
);

    reg [7:0] cmd_opcodes [0:CMD_TABLE_SIZE-1];
    reg [3:0] cmd_param_lens [0:CMD_TABLE_SIZE-1];
    
    initial begin
        cmd_opcodes[0] = 8'h01; cmd_param_lens[0] = 4'd2;
        cmd_opcodes[1] = 8'h02; cmd_param_lens[1] = 4'd1;
        cmd_opcodes[2] = 8'h03; cmd_param_lens[2] = 4'd3;
        cmd_opcodes[3] = 8'h04; cmd_param_lens[3] = 4'd0;
    end
    
    reg [2:0] state;
    reg [3:0] param_counter;
    reg [3:0] current_cmd_index;
    reg cmd_found;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            param_reg <= 0;
            cmd_ready <= 1;
            param_counter <= 0;
            current_cmd_index <= 0;
            cmd_found <= 0;
        end else begin
            case(state)
                0: begin
                    if (cmd_valid && cmd_ready) begin
                        cmd_found <= (cmd_byte == cmd_opcodes[0]) || 
                                    (cmd_byte == cmd_opcodes[1]) || 
                                    (cmd_byte == cmd_opcodes[2]);
                        
                        if (cmd_byte == cmd_opcodes[0]) begin
                            param_counter <= cmd_param_lens[0];
                            current_cmd_index <= 0;
                        end
                        if (cmd_byte == cmd_opcodes[1]) begin
                            param_counter <= cmd_param_lens[1];
                            current_cmd_index <= 1;
                        end
                        if (cmd_byte == cmd_opcodes[2]) begin
                            param_counter <= cmd_param_lens[2];
                            current_cmd_index <= 2;
                        end
                        
                        if (cmd_found) begin
                            state <= 1;
                            cmd_ready <= 0;
                        end
                    end
                end
                
                1: begin
                    if (cmd_valid) begin
                        param_reg <= {param_reg[7:0], cmd_byte};
                        if (param_counter <= 1) begin
                            state <= 2;
                            cmd_ready <= 1;
                        end else begin
                            param_counter <= param_counter - 1;
                        end
                    end
                end
                
                2: begin
                    state <= 0;
                end
                
                default: begin
                    state <= 0;
                end
            endcase
        end
    end
endmodule