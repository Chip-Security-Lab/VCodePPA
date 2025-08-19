//SystemVerilog
module priority_encoder_reg (
    input clk,
    input [7:0] requests,
    output reg [2:0] grant_id,
    output reg valid
);

    // 请求检测子模块
    request_detector u_request_detector (
        .requests(requests),
        .valid(valid)
    );

    // 优先级编码子模块
    priority_encoder u_priority_encoder (
        .clk(clk),
        .requests(requests),
        .grant_id(grant_id)
    );

endmodule

module request_detector (
    input [7:0] requests,
    output reg valid
);
    always @(*) begin
        valid = |requests;
    end
endmodule

module priority_encoder (
    input clk,
    input [7:0] requests,
    output reg [2:0] grant_id
);
    reg [7:0] request_priority;
    
    always @(posedge clk) begin
        request_priority = 8'b0;
        if (requests[0]) request_priority[0] = 1'b1;
        else if (requests[1]) request_priority[1] = 1'b1;
        else if (requests[2]) request_priority[2] = 1'b1;
        else if (requests[3]) request_priority[3] = 1'b1;
        else if (requests[4]) request_priority[4] = 1'b1;
        else if (requests[5]) request_priority[5] = 1'b1;
        else if (requests[6]) request_priority[6] = 1'b1;
        else if (requests[7]) request_priority[7] = 1'b1;
        
        case (request_priority)
            8'b00000001: grant_id <= 3'd0;
            8'b00000010: grant_id <= 3'd1;
            8'b00000100: grant_id <= 3'd2;
            8'b00001000: grant_id <= 3'd3;
            8'b00010000: grant_id <= 3'd4;
            8'b00100000: grant_id <= 3'd5;
            8'b01000000: grant_id <= 3'd6;
            8'b10000000: grant_id <= 3'd7;
            default: grant_id <= 3'd0;
        endcase
    end
endmodule