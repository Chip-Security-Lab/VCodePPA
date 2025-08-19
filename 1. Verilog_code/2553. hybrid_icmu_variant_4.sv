//SystemVerilog
module hybrid_icmu (
    input clk, rst_n,
    input [15:0] maskable_int,
    input [3:0] unmaskable_int,
    input [15:0] mask,
    output [4:0] int_id,
    output int_valid,
    output unmaskable_active
);

    wire [15:0] masked_int;
    wire [19:0] combined_pending;
    wire [4:0] priority_int_id;
    wire priority_valid;
    wire priority_unmaskable;
    wire processing;

    masking_unit mask_unit (
        .maskable_int(maskable_int),
        .mask(mask),
        .unmaskable_int(unmaskable_int),
        .masked_int(masked_int),
        .combined_pending(combined_pending)
    );

    priority_encoder priority_unit (
        .combined_pending(combined_pending),
        .int_id(priority_int_id),
        .int_valid(priority_valid),
        .unmaskable_active(priority_unmaskable)
    );

    control_unit ctrl_unit (
        .clk(clk),
        .rst_n(rst_n),
        .priority_valid(priority_valid),
        .priority_int_id(priority_int_id),
        .priority_unmaskable(priority_unmaskable),
        .int_id(int_id),
        .int_valid(int_valid),
        .unmaskable_active(unmaskable_active),
        .processing(processing)
    );

endmodule

module masking_unit (
    input [15:0] maskable_int,
    input [15:0] mask,
    input [3:0] unmaskable_int,
    output [15:0] masked_int,
    output [19:0] combined_pending
);

    assign masked_int = maskable_int & mask;
    assign combined_pending = {unmaskable_int, masked_int};

endmodule

module priority_encoder (
    input [19:0] combined_pending,
    output reg [4:0] int_id,
    output reg int_valid,
    output reg unmaskable_active
);

    always @(*) begin
        int_valid = 1'b0;
        unmaskable_active = 1'b0;
        int_id = 5'd0;
        
        if (|combined_pending) begin
            int_valid = 1'b1;
            
            if (combined_pending[19]) begin
                int_id = 5'd19;
                unmaskable_active = 1'b1;
            end
            else if (combined_pending[18]) begin
                int_id = 5'd18;
                unmaskable_active = 1'b1;
            end
            else if (combined_pending[17]) begin
                int_id = 5'd17;
                unmaskable_active = 1'b1;
            end
            else if (combined_pending[16]) begin
                int_id = 5'd16;
                unmaskable_active = 1'b1;
            end
            else if (combined_pending[15]) begin
                int_id = 5'd15;
            end
            else if (combined_pending[14]) begin
                int_id = 5'd14;
            end
            else if (combined_pending[13]) begin
                int_id = 5'd13;
            end
            else if (combined_pending[12]) begin
                int_id = 5'd12;
            end
            else if (combined_pending[11]) begin
                int_id = 5'd11;
            end
            else if (combined_pending[10]) begin
                int_id = 5'd10;
            end
            else if (combined_pending[9]) begin
                int_id = 5'd9;
            end
            else if (combined_pending[8]) begin
                int_id = 5'd8;
            end
            else if (combined_pending[7]) begin
                int_id = 5'd7;
            end
            else if (combined_pending[6]) begin
                int_id = 5'd6;
            end
            else if (combined_pending[5]) begin
                int_id = 5'd5;
            end
            else if (combined_pending[4]) begin
                int_id = 5'd4;
            end
            else if (combined_pending[3]) begin
                int_id = 5'd3;
            end
            else if (combined_pending[2]) begin
                int_id = 5'd2;
            end
            else if (combined_pending[1]) begin
                int_id = 5'd1;
            end
            else if (combined_pending[0]) begin
                int_id = 5'd0;
            end
        end
    end

endmodule

module control_unit (
    input clk, rst_n,
    input priority_valid,
    input [4:0] priority_int_id,
    input priority_unmaskable,
    output reg [4:0] int_id,
    output reg int_valid,
    output reg unmaskable_active,
    output reg processing
);

    reg [4:0] int_id_next;
    reg int_valid_next;
    reg unmaskable_active_next;
    reg processing_next;

    always @(*) begin
        int_id_next = int_id;
        int_valid_next = int_valid;
        unmaskable_active_next = unmaskable_active;
        processing_next = processing;
        
        if (!processing) begin
            if (priority_valid) begin
                int_id_next = priority_int_id;
                int_valid_next = 1'b1;
                unmaskable_active_next = priority_unmaskable;
                processing_next = 1'b1;
            end
        end
        else begin
            int_valid_next = 1'b0;
            unmaskable_active_next = 1'b0;
            processing_next = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_id <= 5'd0;
            int_valid <= 1'b0;
            unmaskable_active <= 1'b0;
            processing <= 1'b0;
        end else begin
            int_id <= int_id_next;
            int_valid <= int_valid_next;
            unmaskable_active <= unmaskable_active_next;
            processing <= processing_next;
        end
    end

endmodule