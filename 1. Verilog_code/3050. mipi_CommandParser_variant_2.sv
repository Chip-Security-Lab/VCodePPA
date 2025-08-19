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

    // Command table definition
    reg [7:0] cmd_opcodes [0:CMD_TABLE_SIZE-1];
    reg [3:0] cmd_param_lens [0:CMD_TABLE_SIZE-1];
    
    // Initialize command table
    initial begin
        cmd_opcodes[0] = 8'h01; cmd_param_lens[0] = 4'd2;
        cmd_opcodes[1] = 8'h02; cmd_param_lens[1] = 4'd1;
        cmd_opcodes[2] = 8'h03; cmd_param_lens[2] = 4'd3;
        cmd_opcodes[3] = 8'h04; cmd_param_lens[3] = 4'd0;
    end
    
    reg [2:0] state;
    reg [3:0] param_counter;
    reg [3:0] current_cmd_index;
    reg [CMD_TABLE_SIZE-1:0] cmd_match_reg;
    wire [CMD_TABLE_SIZE-1:0] cmd_match;
    wire [3:0] matched_index;
    wire cmd_found;
    
    // Buffered command matching
    genvar i;
    generate
        for (i = 0; i < CMD_TABLE_SIZE; i = i + 1) begin : cmd_match_gen
            assign cmd_match[i] = (cmd_byte == cmd_opcodes[i]);
        end
    endgenerate
    
    // Register buffering for high fanout signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_match_reg <= 0;
        end else begin
            cmd_match_reg <= cmd_match;
        end
    end
    
    // Priority encoder for matched command with buffering
    reg [3:0] matched_index_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            matched_index_reg <= 0;
        end else begin
            matched_index_reg <= cmd_match_reg[0] ? 4'd0 :
                               cmd_match_reg[1] ? 4'd1 :
                               cmd_match_reg[2] ? 4'd2 :
                               cmd_match_reg[3] ? 4'd3 : 4'd0;
        end
    end
    
    assign cmd_found = |cmd_match_reg;
    assign matched_index = matched_index_reg;
    
    // Parameter length buffering
    reg [3:0] param_len_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            param_len_reg <= 0;
        end else if (state == 0 && cmd_valid && cmd_ready && cmd_found) begin
            param_len_reg <= cmd_param_lens[matched_index];
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            param_reg <= 0;
            cmd_ready <= 1;
            param_counter <= 0;
            current_cmd_index <= 0;
        end else begin
            case(state)
                0: begin
                    if (cmd_valid && cmd_ready) begin
                        if (cmd_found) begin
                            param_counter <= param_len_reg;
                            current_cmd_index <= matched_index;
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
                
                default: state <= 0;
            endcase
        end
    end
endmodule