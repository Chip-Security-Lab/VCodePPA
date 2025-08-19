//SystemVerilog
module multilevel_icmu (
    input clock, resetn,
    input [7:0] interrupts,
    input [15:0] priority_level_flat, // 修改为扁平化数组
    input ack_done,
    output reg [2:0] int_number,
    output reg [31:0] saved_context,
    input [31:0] current_context
);
    wire [1:0] priority_level [0:7]; // 内部数组
    reg [7:0] level0_mask, level1_mask, level2_mask, level3_mask;
    reg [1:0] current_level;
    reg handle_active;

    // 从扁平数组提取优先级
    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin: prio_level_map
            assign priority_level[g] = priority_level_flat[g*2+1:g*2];
        end
    endgenerate

    // 计算掩码 - 使用 if-else 结构
    always @(*) begin
        // Initialize masks to 0
        level0_mask = 8'd0;
        level1_mask = 8'd0;
        level2_mask = 8'd0;
        level3_mask = 8'd0;

        // Unrolled logic for each bit i = 0 to 7 using if-else if
        // i = 0
        if (priority_level[0] == 2'd0) level0_mask[0] = 1'b1;
        else if (priority_level[0] == 2'd1) level1_mask[0] = 1'b1;
        else if (priority_level[0] == 2'd2) level2_mask[0] = 1'b1;
        else if (priority_level[0] == 2'd3) level3_mask[0] = 1'b1;

        // i = 1
        if (priority_level[1] == 2'd0) level0_mask[1] = 1'b1;
        else if (priority_level[1] == 2'd1) level1_mask[1] = 1'b1;
        else if (priority_level[1] == 2'd2) level2_mask[1] = 1'b1;
        else if (priority_level[1] == 2'd3) level3_mask[1] = 1'b1;

        // i = 2
        if (priority_level[2] == 2'd0) level0_mask[2] = 1'b1;
        else if (priority_level[2] == 2'd1) level1_mask[2] = 1'b1;
        else if (priority_level[2] == 2'd2) level2_mask[2] = 1'b1;
        else if (priority_level[2] == 2'd3) level3_mask[2] = 1'b1;

        // i = 3
        if (priority_level[3] == 2'd0) level0_mask[3] = 1'b1;
        else if (priority_level[3] == 2'd1) level1_mask[3] = 1'b1;
        else if (priority_level[3] == 2'd2) level2_mask[3] = 1'b1;
        else if (priority_level[3] == 2'd3) level3_mask[3] = 1'b1;

        // i = 4
        if (priority_level[4] == 2'd0) level0_mask[4] = 1'b1;
        else if (priority_level[4] == 2'd1) level1_mask[4] = 1'b1;
        else if (priority_level[4] == 2'd2) level2_mask[4] = 1'b1;
        else if (priority_level[4] == 2'd3) level3_mask[4] = 1'b1;

        // i = 5
        if (priority_level[5] == 2'd0) level0_mask[5] = 1'b1;
        else if (priority_level[5] == 2'd1) level1_mask[5] = 1'b1;
        else if (priority_level[5] == 2'd2) level2_mask[5] = 1'b1;
        else if (priority_level[5] == 2'd3) level3_mask[5] = 1'b1;

        // i = 6
        if (priority_level[6] == 2'd0) level0_mask[6] = 1'b1;
        else if (priority_level[6] == 2'd1) level1_mask[6] = 1'b1;
        else if (priority_level[6] == 2'd2) level2_mask[6] = 1'b1;
        else if (priority_level[6] == 2'd3) level3_mask[6] = 1'b1;

        // i = 7
        if (priority_level[7] == 2'd0) level0_mask[7] = 1'b1;
        else if (priority_level[7] == 2'd1) level1_mask[7] = 1'b1;
        else if (priority_level[7] == 2'd2) level2_mask[7] = 1'b1;
        else if (priority_level[7] == 2'd3) level3_mask[7] = 1'b1;
    end

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            int_number <= 3'd0;
            handle_active <= 1'b0;
            current_level <= 2'd0;
            saved_context <= 32'd0;
        end else if (!handle_active && |interrupts) begin
            if (|(interrupts & level3_mask)) begin
                int_number <= find_first_set(interrupts & level3_mask);
                current_level <= 2'd3;
            end else if (|(interrupts & level2_mask)) begin
                int_number <= find_first_set(interrupts & level2_mask);
                current_level <= 2'd2;
            end else if (|(interrupts & level1_mask)) begin
                int_number <= find_first_set(interrupts & level1_mask);
                current_level <= 2'd1;
            end else begin
                int_number <= find_first_set(interrupts & level0_mask);
                current_level <= 2'd0;
            end
            handle_active <= 1'b1;
            saved_context <= current_context;
        end else if (handle_active && ack_done) begin
            handle_active <= 1'b0;
        end
    end

    // Function implementation remains the same
    function [2:0] find_first_set;
        input [7:0] bits;
        reg [2:0] result;
        begin
            casez(bits)
                8'b???????1: result = 3'd0;
                8'b??????10: result = 3'd1;
                8'b?????100: result = 3'd2;
                8'b????1000: result = 3'd3;
                8'b???10000: result = 3'd4;
                8'b??100000: result = 3'd5;
                8'b?1000000: result = 3'd6;
                8'b10000000: result = 3'd7;
                default: result = 3'd0;
            endcase
            find_first_set = result;
        end
    endfunction
endmodule