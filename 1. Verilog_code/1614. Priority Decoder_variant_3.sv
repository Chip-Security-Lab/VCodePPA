//SystemVerilog
module priority_decoder (
    input [3:0] request,
    output [1:0] grant,
    output valid
);

    // 优先级检测子模块
    priority_detector u_priority_detector (
        .request(request),
        .priority_level(priority_level),
        .has_request(has_request)
    );

    // 授权生成子模块
    grant_generator u_grant_generator (
        .priority_level(priority_level),
        .has_request(has_request),
        .grant(grant),
        .valid(valid)
    );

endmodule

module priority_detector (
    input [3:0] request,
    output reg [1:0] priority_level,
    output reg has_request
);
    always @(*) begin
        casex (request)
            4'bxxx1: begin priority_level = 2'b00; has_request = 1'b1; end
            4'bxx10: begin priority_level = 2'b01; has_request = 1'b1; end
            4'bx100: begin priority_level = 2'b10; has_request = 1'b1; end
            4'b1000: begin priority_level = 2'b11; has_request = 1'b1; end
            default: begin priority_level = 2'b00; has_request = 1'b0; end
        endcase
    end
endmodule

module grant_generator (
    input [1:0] priority_level,
    input has_request,
    output reg [1:0] grant,
    output reg valid
);
    always @(*) begin
        grant = priority_level;
        valid = has_request;
    end
endmodule