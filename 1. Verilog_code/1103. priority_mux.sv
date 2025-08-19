module priority_mux (
    input wire [3:0] requests,    // Request signals
    input wire [7:0] data_0, data_1, data_2, data_3, // Data sources
    output reg [7:0] granted_data, // Selected data output
    output reg [1:0] grant_id     // ID of granted request
);
    always @(*) begin
        if (requests[3]) begin
            grant_id = 2'b11; granted_data = data_3;
        end else if (requests[2]) begin
            grant_id = 2'b10; granted_data = data_2;
        end else if (requests[1]) begin
            grant_id = 2'b01; granted_data = data_1;
        end else begin
            grant_id = 2'b00; granted_data = data_0;
        end
    end
endmodule