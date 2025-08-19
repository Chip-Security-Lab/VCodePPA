//SystemVerilog
module bidirectional_cdc #(parameter WIDTH = 8) (
    input wire clk_a, clk_b, rst_n,
    // A to B path
    input wire [WIDTH-1:0] data_a_to_b,
    input wire req_a_to_b,
    output wire ack_a_to_b,
    output reg [WIDTH-1:0] data_b_from_a,
    // B to A path
    input wire [WIDTH-1:0] data_b_to_a,
    input wire req_b_to_a,
    output wire ack_b_to_a,
    output reg [WIDTH-1:0] data_a_from_b
);
    // A to B path
    reg req_a_toggle;
    reg [WIDTH-1:0] data_a_reg;
    reg [2:0] req_a_sync;
    reg ack_a_toggle;
    reg [2:0] ack_a_sync;

    // B to A path
    reg req_b_toggle;
    reg [WIDTH-1:0] data_b_reg;
    reg [2:0] req_b_sync;
    reg ack_b_toggle;
    reg [2:0] ack_b_sync;

    // 3-bit conditional-invert subtractor function
    function [2:0] cond_inv_sub_3bit;
        input [2:0] minuend;
        input [2:0] subtrahend;
        reg [2:0] subtrahend_inv;
        reg [2:0] sum;
        reg carry;
        integer i;
        begin
            // Conditional invert subtrahend bits
            for (i = 0; i < 3; i = i + 1)
                subtrahend_inv[i] = ~subtrahend[i];
            // Add minuend, inverted subtrahend, and 1
            carry = 1'b1;
            for (i = 0; i < 3; i = i + 1) begin
                sum[i] = minuend[i] ^ subtrahend_inv[i] ^ carry;
                carry = (minuend[i] & subtrahend_inv[i]) | (minuend[i] & carry) | (subtrahend_inv[i] & carry);
            end
            cond_inv_sub_3bit = sum;
        end
    endfunction

    // A to B request logic
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_a_toggle <= 1'b0;
            data_a_reg <= {WIDTH{1'b0}};
            ack_a_sync <= 3'b0;
        end else begin
            ack_a_sync <= {ack_a_sync[1:0], ack_a_toggle};

            // Use 3-bit conditional-invert subtractor for toggle comparison
            if (req_a_to_b && (cond_inv_sub_3bit({2'b0, req_a_toggle}, {2'b0, ack_a_sync[2]}) == 3'b000)) begin
                req_a_toggle <= ~req_a_toggle;
                data_a_reg <= data_a_to_b;
            end
        end
    end

    // A to B receive logic
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_a_sync <= 3'b0;
            ack_a_toggle <= 1'b0;
            data_b_from_a <= {WIDTH{1'b0}};
        end else begin
            req_a_sync <= {req_a_sync[1:0], req_a_toggle};

            // Use 3-bit conditional-invert subtractor for toggle difference
            if (cond_inv_sub_3bit({2'b0, req_a_sync[2]}, {2'b0, ack_a_toggle}) != 3'b000) begin
                ack_a_toggle <= req_a_sync[2];
                data_b_from_a <= data_a_reg;
            end
        end
    end

    // B to A request logic
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_b_toggle <= 1'b0;
            data_b_reg <= {WIDTH{1'b0}};
            ack_b_sync <= 3'b0;
        end else begin
            ack_b_sync <= {ack_b_sync[1:0], ack_b_toggle};

            // Use 3-bit conditional-invert subtractor for toggle comparison
            if (req_b_to_a && (cond_inv_sub_3bit({2'b0, req_b_toggle}, {2'b0, ack_b_sync[2]}) == 3'b000)) begin
                req_b_toggle <= ~req_b_toggle;
                data_b_reg <= data_b_to_a;
            end
        end
    end

    // B to A receive logic
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_b_sync <= 3'b0;
            ack_b_toggle <= 1'b0;
            data_a_from_b <= {WIDTH{1'b0}};
        end else begin
            req_b_sync <= {req_b_sync[1:0], req_b_toggle};

            // Use 3-bit conditional-invert subtractor for toggle difference
            if (cond_inv_sub_3bit({2'b0, req_b_sync[2]}, {2'b0, ack_b_toggle}) != 3'b000) begin
                ack_b_toggle <= req_b_sync[2];
                data_a_from_b <= data_b_reg;
            end
        end
    end

    // Acknowledgment signals
    assign ack_a_to_b = (cond_inv_sub_3bit({2'b0, req_a_toggle}, {2'b0, ack_a_sync[2]}) == 3'b000);
    assign ack_b_to_a = (cond_inv_sub_3bit({2'b0, req_b_toggle}, {2'b0, ack_b_sync[2]}) == 3'b000);
endmodule