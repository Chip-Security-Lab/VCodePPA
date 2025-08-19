module thermometer_encoder(
    input [2:0] bin,
    output reg [7:0] th_code
);

    always @(*) begin
        if (bin[2]) begin
            if (bin[1]) begin
                if (bin[0]) begin
                    th_code = 8'b00000001;
                end else begin
                    th_code = 8'b00000011;
                end
            end else begin
                if (bin[0]) begin
                    th_code = 8'b00000111;
                end else begin
                    th_code = 8'b00001111;
                end
            end
        end else begin
            if (bin[1]) begin
                if (bin[0]) begin
                    th_code = 8'b00011111;
                end else begin
                    th_code = 8'b00111111;
                end
            end else begin
                if (bin[0]) begin
                    th_code = 8'b01111111;
                end else begin
                    th_code = 8'b11111111;
                end
            end
        end
    end

endmodule