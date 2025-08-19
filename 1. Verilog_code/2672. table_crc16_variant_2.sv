//SystemVerilog
module table_crc16(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg data_ready,
    output reg [15:0] crc_result,
    output reg crc_valid
);

    reg [15:0] crc_table [0:255];
    reg [1:0] ctrl_state;
    wire [15:0] crc_next;
    wire [15:0] crc_temp;
    reg processing;
    
    // Control state logic
    always @(*) begin
        if (reset) 
            ctrl_state = 2'b01;
        else if (data_valid && data_ready)
            ctrl_state = 2'b10;
        else
            ctrl_state = 2'b00;
    end
    
    // Ready signal generation
    always @(posedge clk) begin
        if (reset)
            data_ready <= 1'b0;
        else
            data_ready <= ~processing;
    end
    
    // Processing flag
    always @(posedge clk) begin
        if (reset)
            processing <= 1'b0;
        else if (data_valid && data_ready)
            processing <= 1'b1;
        else if (ctrl_state == 2'b10)
            processing <= 1'b0;
    end
    
    // CRC calculation
    assign crc_temp = crc_result ^ {8'h00, data_in};
    
    assign crc_next = (ctrl_state == 2'b01) ? 16'hFFFF : 
                      (ctrl_state == 2'b10) ? (crc_result >> 8) ^ crc_table[crc_temp[7:0]] :
                                              crc_result;
    
    // Register updates
    always @(posedge clk) begin
        if (reset) begin
            crc_result <= 16'hFFFF;
            crc_valid <= 1'b0;
        end
        else begin
            crc_result <= crc_next;
            crc_valid <= (ctrl_state == 2'b10);
        end
    end

endmodule