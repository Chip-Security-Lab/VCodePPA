//SystemVerilog
module barrel_shifter_sync_cl (
    input clk, rst_n, en,
    input [7:0] data_in,
    input [2:0] shift_amount,
    output reg [7:0] data_out
);
    // 位移结果暂存
    reg [7:0] shifted_data;
    
    always @(*) begin
        case (shift_amount)
            3'd0: shifted_data = data_in;
            3'd1: shifted_data = {data_in[6:0], data_in[7]};
            3'd2: shifted_data = {data_in[5:0], data_in[7:6]};
            3'd3: shifted_data = {data_in[4:0], data_in[7:5]};
            3'd4: shifted_data = {data_in[3:0], data_in[7:4]};
            3'd5: shifted_data = {data_in[2:0], data_in[7:3]};
            3'd6: shifted_data = {data_in[1:0], data_in[7:2]};
            3'd7: shifted_data = {data_in[0], data_in[7:1]};
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (en)
            data_out <= shifted_data;
    end
endmodule