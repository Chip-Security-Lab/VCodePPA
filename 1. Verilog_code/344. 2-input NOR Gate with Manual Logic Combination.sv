module nor2_logic (
    input wire A, B,
    output wire Y
);
    wire or_out;
    or u1 (or_out, A, B);  // 使用或门
    not u2 (Y, or_out);  // 使用反向门
endmodule
